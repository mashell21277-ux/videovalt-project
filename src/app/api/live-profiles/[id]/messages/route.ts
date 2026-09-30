import { NextRequest, NextResponse } from "next/server";
import { db } from "@/lib/db";
import { isAdmin } from "@/lib/auth";

type RouteContext = { params: Promise<{ id: string }> };

export async function GET(_request: NextRequest, context: RouteContext) {
  const { id } = await context.params;

  const messages = await db.profileMessage.findMany({
    where: { profileId: id },
    orderBy: { createdAt: "asc" },
    take: 200,
  });

  return NextResponse.json(
    messages.map((m) => ({
      ...m,
      createdAt: m.createdAt.toISOString(),
    }))
  );
}

export async function POST(request: NextRequest, context: RouteContext) {
  const { id } = await context.params;

  const profile = await db.liveProfile.findUnique({ where: { id } });
  if (!profile) {
    return NextResponse.json({ error: "Profile not found" }, { status: 404 });
  }

  const body = await request.json();
  const authorName = (body.authorName as string)?.trim() || "Guest";
  const content = (body.content as string)?.trim();

  if (!content) {
    return NextResponse.json({ error: "Message is required" }, { status: 400 });
  }

  if (content.length > 500) {
    return NextResponse.json({ error: "Message too long" }, { status: 400 });
  }

  const message = await db.profileMessage.create({
    data: {
      profileId: id,
      authorName: authorName.slice(0, 40),
      content,
    },
  });

  await db.liveProfile.update({
    where: { id },
    data: { updatedAt: new Date() },
  });

  return NextResponse.json(
    { ...message, createdAt: message.createdAt.toISOString() },
    { status: 201 }
  );
}

export async function DELETE(request: NextRequest, context: RouteContext) {
  if (!(await isAdmin(request))) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { searchParams } = new URL(request.url);
  const messageId = searchParams.get("messageId");
  if (!messageId) {
    return NextResponse.json({ error: "messageId required" }, { status: 400 });
  }

  await db.profileMessage.delete({ where: { id: messageId } });

  return NextResponse.json({ ok: true });
}
