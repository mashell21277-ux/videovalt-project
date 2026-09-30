import { VideoCategory } from "@prisma/client";

export const CATEGORIES: {
  key: VideoCategory;
  label: string;
  color: string;
  icon: string;
}[] = [
  {
    key: "ENTERTAINMENT",
    label: "Entertainment",
    color: "from-violet-500 to-purple-600",
    icon: "🎬",
  },
  {
    key: "EDUCATION",
    label: "Education",
    color: "from-blue-500 to-cyan-600",
    icon: "📚",
  },
  {
    key: "MUSIC",
    label: "Music",
    color: "from-pink-500 to-rose-600",
    icon: "🎵",
  },
  {
    key: "SPORTS",
    label: "Sports",
    color: "from-emerald-500 to-green-600",
    icon: "⚽",
  },
];

export const CATEGORY_MAP = Object.fromEntries(
  CATEGORIES.map((c) => [c.key, c])
) as Record<VideoCategory, (typeof CATEGORIES)[number]>;
