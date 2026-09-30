import { NextRequest, NextResponse } from "next/server";
import { db } from "@/lib/db";
import { isAdmin } from "@/lib/auth";

export async function GET(request: NextRequest) {
  try {
    const admin = await isAdmin(request);

    const notifications = await db.appNotification.findMany({
      where: admin ? undefined : { isActive: true },
      orderBy: { createdAt: "desc" },
      take: admin ? 100 : 50,
    });

    return NextResponse.json(
      notifications.map((n) => ({
        ...n,
        createdAt: n.createdAt.toISOString(),
      }))
    );
  } catch (error) {
    console.error("List notifications error:", error);
    return NextResponse.json({ error: "Could not load notifications" }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  if (!(await isAdmin(request))) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  try {
    const body = await request.json();
    const title = (body.title as string)?.trim();
    const message = (body.body as string)?.trim();

    if (!title || !message) {
      return NextResponse.json(
        { error: "Title and message are required" },
        { status: 400 }
      );
    }

    const notification = await db.appNotification.create({
      data: { title, body: message, isActive: true },
    });

    return NextResponse.json(
      {
        ...notification,
        createdAt: notification.createdAt.toISOString(),
      },
      { status: 201 }
    );
  } catch (error) {
    console.error("Create notification error:", error);
    return NextResponse.json({ error: "Could not send notification" }, { status: 400 });
  }
}
