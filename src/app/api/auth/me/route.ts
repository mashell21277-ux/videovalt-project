import { NextRequest, NextResponse } from "next/server";
import { isAdmin } from "@/lib/auth";

export async function GET(request: NextRequest) {
  const admin = await isAdmin(request);
  return NextResponse.json({ isAdmin: admin });
}
