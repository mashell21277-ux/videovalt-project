import { NextRequest, NextResponse } from "next/server";
import { db } from "@/lib/db";
import { isAdmin } from "@/lib/auth";
import { resolveAvatarUrl } from "@/lib/avatar-url";

type RouteContext = { params: Promise<{ id: string }> };

export async function GET(request: NextRequest, context: RouteContext) {
  const { id } = await context.params;
  const admin = await isAdmin(request);

  const profile = await db.liveProfile.findUnique({
    where: { id },
    include: {
      videos: { orderBy: { createdAt: "desc" } },
      messages: { orderBy: { createdAt: "asc" }, take: 100 },
    },
  });

  if (!profile || (!profile.isVisible && !admin)) {
    return NextResponse.json({ error: "Profile not found" }, { status: 404 });
  }

  return NextResponse.json({
    id: profile.id,
    name: profile.name,
    handle: profile.handle,
    avatarUrl: resolveAvatarUrl(profile.avatarUrl),
    bio: profile.bio,
    isVisible: profile.isVisible,
    createdAt: profile.createdAt.toISOString(),
    updatedAt: profile.updatedAt.toISOString(),
    videos: profile.videos.map((v) => ({
      ...v,
      createdAt: v.createdAt.toISOString(),
      updatedAt: v.updatedAt.toISOString(),
    })),
    messages: profile.messages.map((m) => ({
      ...m,
      createdAt: m.createdAt.toISOString(),
    })),
  });
}

export async function PATCH(request: NextRequest, context: RouteContext) {
  if (!(await isAdmin(request))) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { id } = await context.params;

  try {
    const body = await request.json();

    if (typeof body.isVisible !== "boolean") {
      return NextResponse.json({ error: "isVisible (boolean) is required" }, { status: 400 });
    }

    const profile = await db.liveProfile.update({
      where: { id },
      data: { isVisible: body.isVisible },
    });

    return NextResponse.json({
      ...profile,
      avatarUrl: resolveAvatarUrl(profile.avatarUrl),
      createdAt: profile.createdAt.toISOString(),
      updatedAt: profile.updatedAt.toISOString(),
    });
  } catch {
    return NextResponse.json({ error: "Profile not found" }, { status: 404 });
  }
}

export async function DELETE(request: NextRequest, context: RouteContext) {
  if (!(await isAdmin(request))) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { id } = await context.params;

  await db.liveProfile.delete({ where: { id } });

  return NextResponse.json({ ok: true });
}
