import { NextRequest, NextResponse } from "next/server";
import { db } from "@/lib/db";
import { isAdmin } from "@/lib/auth";

type RouteContext = { params: Promise<{ id: string }> };

export async function PATCH(request: NextRequest, context: RouteContext) {
  if (!(await isAdmin(request))) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { id } = await context.params;
  const body = await request.json();

  if (typeof body.isActive !== "boolean") {
    return NextResponse.json({ error: "isActive (boolean) required" }, { status: 400 });
  }

  try {
    const notification = await db.appNotification.update({
      where: { id },
      data: { isActive: body.isActive },
    });

    return NextResponse.json({
      ...notification,
      createdAt: notification.createdAt.toISOString(),
    });
  } catch {
    return NextResponse.json({ error: "Notification not found" }, { status: 404 });
  }
}

export async function DELETE(request: NextRequest, context: RouteContext) {
  if (!(await isAdmin(request))) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { id } = await context.params;

  await db.appNotification.delete({ where: { id } });

  return NextResponse.json({ ok: true });
}
