"use client";

import { useState } from "react";
import { Play, X } from "lucide-react";
import type { Video } from "@/types/video";
import { CATEGORY_MAP } from "@/lib/constants";
import { getVideoPlaybackUrl } from "@/lib/video-url";
import { formatFileSize, formatDuration } from "@/lib/utils";
import { DownloadButton } from "./DownloadButton";

interface VideoCardProps {
  video: Video;
}

export function VideoCard({ video }: VideoCardProps) {
  const [isPlaying, setIsPlaying] = useState(false);
  const category = CATEGORY_MAP[video.category];
  const playbackUrl = getVideoPlaybackUrl(video);

  return (
    <>
      <article className="group overflow-hidden rounded-xl border border-white/5 bg-white/[0.03] transition-all hover:border-white/10 hover:bg-white/[0.06]">
        <button
          onClick={() => setIsPlaying(true)}
          className="relative aspect-video w-full overflow-hidden bg-zinc-900"
        >
          <video
            src={`${playbackUrl}${video.sourceUrl ? "" : "#t=0.5"}`}
            className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
            preload="metadata"
            muted
          />
          <div className="absolute inset-0 flex items-center justify-center bg-black/30 opacity-0 transition-opacity group-hover:opacity-100">
            <div className="flex h-12 w-12 items-center justify-center rounded-full bg-white/20 backdrop-blur-sm">
              <Play className="h-5 w-5 fill-white text-white" />
            </div>
          </div>
          {video.duration && (
            <span className="absolute bottom-2 right-2 rounded-md bg-black/70 px-1.5 py-0.5 text-xs text-white">
              {formatDuration(video.duration)}
            </span>
          )}
        </button>

        <div className="p-3">
          <h3 className="truncate text-sm font-medium text-white">
            {video.title}
          </h3>
          <div className="mt-1 flex items-center justify-between">
            <span className="text-xs text-zinc-500">
              {formatFileSize(video.fileSize)}
            </span>
            <DownloadButton video={video} variant="compact" />
          </div>
        </div>
      </article>

      {isPlaying && (
        <div
          className="fixed inset-0 z-[100] flex items-center justify-center bg-black/90 p-4 backdrop-blur-sm"
          onClick={() => setIsPlaying(false)}
        >
          <div
            className="relative w-full max-w-4xl"
            onClick={(e) => e.stopPropagation()}
          >
            <button
              onClick={() => setIsPlaying(false)}
              className="absolute -top-12 right-0 flex h-10 w-10 items-center justify-center rounded-full bg-white/10 text-white transition-colors hover:bg-white/20"
            >
              <X className="h-5 w-5" />
            </button>
            <video
              src={playbackUrl}
              controls
              autoPlay
              className="w-full rounded-xl"
            />
            <div className="mt-4 flex items-center justify-between">
              <div>
                <h2 className="text-lg font-semibold text-white">
                  {video.title}
                </h2>
                <p className="text-sm text-zinc-400">
                  {category.icon} {category.label}
                </p>
              </div>
              <DownloadButton video={video} />
            </div>
          </div>
        </div>
      )}
    </>
  );
}
