import { NextRequest, NextResponse } from "next/server";
import { writeFile, mkdir } from "fs/promises";
import path from "path";
import { v4 as uuidv4 } from "uuid";
import { db } from "@/lib/db";
import { isAdmin } from "@/lib/auth";
import { slugifyHandle } from "@/lib/slug";
import { resolveAvatarUrl } from "@/lib/avatar-url";

const AVATAR_DIR = path.join(process.cwd(), "public", "uploads", "avatars");

function mapProfile(
  p: {
    id: string;
    name: string;
    handle: string;
    avatarUrl: string | null;
    bio: string | null;
    isVisible: boolean;
    createdAt: Date;
    updatedAt: Date;
    videos: Array<{
      id: string;
      createdAt: Date;
      updatedAt: Date;
      [key: string]: unknown;
    }>;
    _count: { videos: number; messages: number };
  }
) {
  return {
    id: p.id,
    name: p.name,
    handle: p.handle,
    avatarUrl: resolveAvatarUrl(p.avatarUrl),
    bio: p.bio,
    isVisible: p.isVisible,
    createdAt: p.createdAt.toISOString(),
    updatedAt: p.updatedAt.toISOString(),
    latestVideo: p.videos[0]
      ? {
          ...p.videos[0],
          createdAt: p.videos[0].createdAt.toISOString(),
          updatedAt: p.videos[0].updatedAt.toISOString(),
        }
      : null,
    videoCount: p._count.videos,
    messageCount: p._count.messages,
  };
}

export async function GET(request: NextRequest) {
  try {
    const admin = await isAdmin(request);

    const profiles = await db.liveProfile.findMany({
      where: admin ? undefined : { isVisible: true },
      orderBy: { updatedAt: "desc" },
      include: {
        videos: {
          where: { isLive: true },
          orderBy: { createdAt: "desc" },
          take: 1,
        },
        _count: { select: { videos: true, messages: true } },
      },
    });

    return NextResponse.json(profiles.map(mapProfile));
  } catch (error) {
    console.error("List profiles error:", error);
    return NextResponse.json(
      { error: "Could not load profiles. Restart the server if you just updated the database." },
      { status: 500 }
    );
  }
}

async function saveAvatarFile(file: File): Promise<string> {
  await mkdir(AVATAR_DIR, { recursive: true });
  const ext = path.extname(file.name) || ".jpg";
  const filename = `${uuidv4()}${ext}`;
  const buffer = Buffer.from(await file.arrayBuffer());
  await writeFile(path.join(AVATAR_DIR, filename), buffer);
  return `/uploads/avatars/${filename}`;
}

export async function POST(request: NextRequest) {
  if (!(await isAdmin(request))) {
    return NextResponse.json({ error: "Unauthorized — sign in again" }, { status: 401 });
  }

  try {
    const contentType = request.headers.get("content-type") ?? "";
    let name = "";
    let bio: string | null = null;
    let avatarUrl: string | null = null;
    let handle = "";

    if (contentType.includes("multipart/form-data")) {
      const formData = await request.formData();
      name = ((formData.get("name") as string) ?? "").trim();
      bio = ((formData.get("bio") as string) ?? "").trim() || null;
      handle = ((formData.get("handle") as string) ?? "").trim();
      const avatarUrlRaw = ((formData.get("avatarUrl") as string) ?? "").trim();
      const avatarFile = formData.get("avatar") as File | null;

      if (avatarFile && avatarFile.size > 0) {
        avatarUrl = await saveAvatarFile(avatarFile);
      } else if (avatarUrlRaw) {
        avatarUrl = avatarUrlRaw;
      }
    } else {
      const body = await request.json();
      name = (body.name as string)?.trim() ?? "";
      bio = (body.bio as string)?.trim() || null;
      avatarUrl = (body.avatarUrl as string)?.trim() || null;
      handle = (body.handle as string)?.trim() ?? "";
    }

    if (!name) {
      return NextResponse.json({ error: "Name is required" }, { status: 400 });
    }

    handle = slugifyHandle(handle || name);

    const existing = await db.liveProfile.findUnique({ where: { handle } });
    if (existing) {
      handle = `${handle}-${Date.now().toString(36).slice(-4)}`;
    }

    const profile = await db.liveProfile.create({
      data: { name, handle, bio, avatarUrl, isVisible: true },
    });

    return NextResponse.json(
      {
        ...profile,
        avatarUrl: resolveAvatarUrl(profile.avatarUrl),
        createdAt: profile.createdAt.toISOString(),
        updatedAt: profile.updatedAt.toISOString(),
      },
      { status: 201 }
    );
  } catch (error) {
    console.error("Create profile error:", error);
    const message =
      error instanceof Error && error.message.includes("liveProfile")
        ? "Database not ready — restart the dev server (npm run dev)"
        : "Could not create profile";
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
