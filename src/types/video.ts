import { VideoCategory, VideoType } from "@prisma/client";

export interface VideoProfileSummary {
  id: string;
  name: string;
  handle: string;
  avatarUrl: string | null;
}

export interface Video {
  id: string;
  title: string;
  description: string | null;
  filename: string | null;
  sourceUrl: string | null;
  thumbnail: string | null;
  category: VideoCategory;
  type: VideoType;
  duration: number | null;
  fileSize: number | null;
  isLive: boolean;
  profileId: string | null;
  profile?: VideoProfileSummary | null;
  createdAt: string;
  updatedAt: string;
}
