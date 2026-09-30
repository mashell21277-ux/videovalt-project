"use client";

import { useEffect, useState } from "react";
import type { Video } from "@/types/video";
import { VideoCard } from "./VideoCard";
import { cn } from "@/lib/utils";

interface CategoryColumnProps {
  categoryKey: string;
  label: string;
  color: string;
  icon: string;
}

export function CategoryColumn({
  categoryKey,
  label,
  color,
  icon,
}: CategoryColumnProps) {
  const [videos, setVideos] = useState<Video[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`/api/videos?category=${categoryKey}&type=VIDEO`)
      .then((res) => res.json())
      .then(setVideos)
      .finally(() => setLoading(false));
  }, [categoryKey]);

  return (
    <section className="flex flex-col">
      <div className="mb-4 flex items-center gap-3">
        <div
          className={cn(
            "flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br text-lg",
            color
          )}
        >
          {icon}
        </div>
        <div>
          <h2 className="text-base font-semibold text-white">{label}</h2>
          <p className="text-xs text-zinc-500">
            {videos.length} video{videos.length !== 1 ? "s" : ""}
          </p>
        </div>
      </div>

      <div className="flex flex-1 flex-col gap-3">
        {loading ? (
          Array.from({ length: 2 }).map((_, i) => (
            <div
              key={i}
              className="aspect-video animate-pulse rounded-xl bg-white/5"
            />
          ))
        ) : videos.length === 0 ? (
          <div className="flex flex-1 items-center justify-center rounded-xl border border-dashed border-white/10 p-8">
            <p className="text-center text-sm text-zinc-500">No videos yet</p>
          </div>
        ) : (
          videos.map((video) => <VideoCard key={video.id} video={video} />)
        )}
      </div>
    </section>
  );
}
