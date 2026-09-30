"use client";

import { useEffect, useRef, useState, useCallback } from "react";
import { ChevronUp, ChevronDown } from "lucide-react";
import type { Video } from "@/types/video";
import { DownloadButton } from "./DownloadButton";
import { CATEGORY_MAP } from "@/lib/constants";
import { getVideoPlaybackUrl } from "@/lib/video-url";

export function ReelsPlayer() {
  const [reels, setReels] = useState<Video[]>([]);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [loading, setLoading] = useState(true);
  const containerRef = useRef<HTMLDivElement>(null);
  const videoRefs = useRef<Map<number, HTMLVideoElement>>(new Map());

  useEffect(() => {
    fetch("/api/videos?type=REEL")
      .then((res) => res.json())
      .then(setReels)
      .finally(() => setLoading(false));
  }, []);

  const playCurrent = useCallback(
    (index: number) => {
      videoRefs.current.forEach((video, i) => {
        if (i === index) {
          video.currentTime = 0;
          video.play().catch(() => {});
        } else {
          video.pause();
        }
      });
    },
    []
  );

  useEffect(() => {
    if (reels.length > 0) playCurrent(currentIndex);
  }, [currentIndex, reels.length, playCurrent]);

  function goTo(index: number) {
    if (index < 0 || index >= reels.length) return;
    setCurrentIndex(index);
  }

  function handleScroll(e: React.WheelEvent) {
    e.preventDefault();
    if (e.deltaY > 0) goTo(currentIndex + 1);
    else if (e.deltaY < 0) goTo(currentIndex - 1);
  }

  if (loading) {
    return (
      <div className="flex h-[calc(100vh-4rem)] items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-violet-500 border-t-transparent" />
      </div>
    );
  }

  if (reels.length === 0) {
    return (
      <div className="flex h-[calc(100vh-4rem)] flex-col items-center justify-center gap-4">
        <div className="text-5xl">🎬</div>
        <h2 className="text-xl font-semibold text-white">No reels yet</h2>
        <p className="text-zinc-400">Check back later for short videos</p>
      </div>
    );
  }

  const current = reels[currentIndex];
  const category = CATEGORY_MAP[current.category];

  return (
    <div
      ref={containerRef}
      onWheel={handleScroll}
      className="relative flex h-[calc(100vh-4rem)] items-center justify-center overflow-hidden bg-black"
    >
      <div className="relative h-full w-full max-w-md">
        {reels.map((reel, index) => (
          <div
            key={reel.id}
            className="absolute inset-0 transition-transform duration-500 ease-out"
            style={{
              transform: `translateY(${(index - currentIndex) * 100}%)`,
            }}
          >
            <video
              ref={(el) => {
                if (el) videoRefs.current.set(index, el);
              }}
              src={getVideoPlaybackUrl(reel)}
              className="h-full w-full object-cover"
              loop
              playsInline
              muted={index !== currentIndex}
            />
          </div>
        ))}

        <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/80 to-transparent p-6 pt-20">
          <p className="mb-1 text-xs font-medium text-violet-400">
            {category.icon} {category.label}
          </p>
          <h3 className="text-lg font-semibold text-white">{current.title}</h3>
          {current.description && (
            <p className="mt-1 line-clamp-2 text-sm text-zinc-300">
              {current.description}
            </p>
          )}
          <div className="mt-4">
            <DownloadButton video={current} />
          </div>
        </div>
      </div>

      <div className="absolute right-4 top-1/2 flex -translate-y-1/2 flex-col gap-2">
        <button
          onClick={() => goTo(currentIndex - 1)}
          disabled={currentIndex === 0}
          className="flex h-10 w-10 items-center justify-center rounded-full bg-white/10 text-white backdrop-blur-sm transition-all hover:bg-white/20 disabled:opacity-30"
        >
          <ChevronUp className="h-5 w-5" />
        </button>
        <span className="text-center text-xs text-zinc-400">
          {currentIndex + 1}/{reels.length}
        </span>
        <button
          onClick={() => goTo(currentIndex + 1)}
          disabled={currentIndex === reels.length - 1}
          className="flex h-10 w-10 items-center justify-center rounded-full bg-white/10 text-white backdrop-blur-sm transition-all hover:bg-white/20 disabled:opacity-30"
        >
          <ChevronDown className="h-5 w-5" />
        </button>
      </div>
    </div>
  );
}
