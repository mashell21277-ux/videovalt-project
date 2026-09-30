import { NextRequest, NextResponse } from "next/server";
import { writeFile, mkdir } from "fs/promises";
import path from "path";
import { v4 as uuidv4 } from "uuid";
import { db } from "@/lib/db";
import { isAdmin } from "@/lib/auth";
import { isValidVideoUrl, normalizeVideoUrl } from "@/lib/video-url";
import { VideoCategory, VideoType } from "@prisma/client";

const UPLOAD_DIR = path.join(process.cwd(), "public", "uploads");

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const category = searchParams.get("category") as VideoCategory | null;
  const type = searchParams.get("type") as VideoType | null;
  const live = searchParams.get("live");

  const profileId = searchParams.get("profileId");

  const videos = await db.video.findMany({
    where: {
      ...(category && { category }),
      ...(type && { type }),
      ...(live === "true" && { isLive: true }),
      ...(live === "false" && { isLive: false }),
      ...(profileId && { profileId }),
    },
    orderBy: { createdAt: "desc" },
    include: {
      profile: {
        select: { id: true, name: true, handle: true, avatarUrl: true },
      },
    },
  });

  return NextResponse.json(
    videos.map((v) => ({
      ...v,
      createdAt: v.createdAt.toISOString(),
      updatedAt: v.updatedAt.toISOString(),
    }))
  );
}

export async function POST(request: NextRequest) {
  if (!(await isAdmin(request))) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  try {
    const formData = await request.formData();
    const file = formData.get("file") as File | null;
    const sourceUrlRaw = (formData.get("sourceUrl") as string)?.trim() || "";
    const title = formData.get("title") as string;
    const description = (formData.get("description") as string) || null;
    const category = formData.get("category") as VideoCategory;
    const type = (formData.get("type") as VideoType) || "VIDEO";
    const isLive = formData.get("isLive") === "true";
    const profileIdRaw = (formData.get("profileId") as string)?.trim() || "";

    if (!title || !category) {
      return NextResponse.json(
        { error: "Title and category are required" },
        { status: 400 }
      );
    }

    const hasFile = file && file.size > 0;
    const hasUrl = sourceUrlRaw.length > 0;

    if (!hasFile && !hasUrl) {
      return NextResponse.json(
        { error: "Provide a video link (Dropbox, etc.) or upload a file" },
        { status: 400 }
      );
    }

    if (hasUrl && !isValidVideoUrl(sourceUrlRaw)) {
      return NextResponse.json(
        { error: "Invalid video URL" },
        { status: 400 }
      );
    }

    if (isLive && !profileIdRaw) {
      return NextResponse.json(
        { error: "Select a live profile to post" },
        { status: 400 }
      );
    }

    if (profileIdRaw) {
      const profile = await db.liveProfile.findUnique({
        where: { id: profileIdRaw },
      });
      if (!profile) {
        return NextResponse.json({ error: "Profile not found" }, { status: 400 });
      }
    }

    if (isLive && profileIdRaw) {
      await db.video.updateMany({
        where: { profileId: profileIdRaw, isLive: true },
        data: { isLive: false },
      });
    }

    if (hasUrl) {
      const video = await db.video.create({
        data: {
          title,
          description,
          sourceUrl: normalizeVideoUrl(sourceUrlRaw),
          category,
          type: isLive ? "VIDEO" : type,
          isLive,
          profileId: profileIdRaw || null,
        },
      });
      if (profileIdRaw) {
        await db.liveProfile.update({
          where: { id: profileIdRaw },
          data: { updatedAt: new Date() },
        });
      }

      return NextResponse.json(
        {
          ...video,
          createdAt: video.createdAt.toISOString(),
          updatedAt: video.updatedAt.toISOString(),
        },
        { status: 201 }
      );
    }

    await mkdir(UPLOAD_DIR, { recursive: true });

    const ext = path.extname(file!.name) || ".mp4";
    const filename = `${uuidv4()}${ext}`;
    const filepath = path.join(UPLOAD_DIR, filename);

    // Store original file bytes — no transcoding or compression (preserves HD quality)
    const buffer = Buffer.from(await file!.arrayBuffer());
    await writeFile(filepath, buffer);

    const video = await db.video.create({
      data: {
        title,
        description,
        filename,
        category,
        type: isLive ? "VIDEO" : type,
        fileSize: buffer.length,
        isLive,
        profileId: profileIdRaw || null,
      },
    });

    if (profileIdRaw) {
      await db.liveProfile.update({
        where: { id: profileIdRaw },
        data: { updatedAt: new Date() },
      });
    }

    return NextResponse.json(
      {
        ...video,
        createdAt: video.createdAt.toISOString(),
        updatedAt: video.updatedAt.toISOString(),
      },
      { status: 201 }
    );
  } catch (error) {
    console.error("Upload error:", error);
    return NextResponse.json({ error: "Upload failed" }, { status: 400 });
  }
}
