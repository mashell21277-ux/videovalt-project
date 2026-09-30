import type { Video } from "./video";

export interface LiveProfile {
  id: string;
  name: string;
  handle: string;
  avatarUrl: string | null;
  bio: string | null;
  isVisible: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface ProfileMessage {
  id: string;
  profileId: string;
  authorName: string;
  content: string;
  createdAt: string;
}

export interface LiveProfileWithLatest extends LiveProfile {
  latestVideo: Video | null;
  videoCount: number;
  messageCount: number;
}

export interface LiveProfileDetail extends LiveProfile {
  videos: Video[];
  messages: ProfileMessage[];
}
