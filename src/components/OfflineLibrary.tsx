"use client";

import { useEffect, useState } from "react";
import { Download, Trash2, Play, X } from "lucide-react";
import {
  getAllOfflineVideos,
  removeOfflineVideo,
  createOfflineVideoUrl,
  type OfflineVideo,
} from "@/lib/offline-storage";
import { CATEGORY_MAP } from "@/lib/constants";

export function OfflineLibrary() {
  const [videos, setVideos] = useState<OfflineVideo[]>([]);
  const [loading, setLoading] = useState(true);
  const [playing, setPlaying] = useState<OfflineVideo | null>(null);

  useEffect(() => {
    loadVideos();
  }, []);

  async function loadVideos() {
    const offline = await getAllOfflineVideos();
    setVideos(offline.sort((a, b) => b.downloadedAt - a.downloadedAt));
    setLoading(false);
  }

  async function handleRemove(id: string) {
    await removeOfflineVideo(id);
    if (playing?.id === id) setPlaying(null);
    loadVideos();
  }

  if (loading) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-violet-500 border-t-transparent" />
      </div>
    );
  }

  if (videos.length === 0) {
    return (
      <div className="flex min-h-[60vh] flex-col items-center justify-center gap-4 px-4">
        <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-white/5">
          <Download className="h-8 w-8 text-zinc-500" />
        </div>
        <h2 className="text-xl font-semibold text-white">
          No offline videos
        </h2>
        <p className="max-w-sm text-center text-zinc-400">
          Download videos from the home page or reels to watch them offline
        </p>
      </div>
    );
  }

  return (
    <>
      <div className="mx-auto max-w-4xl px-4 py-8">
        <h1 className="mb-2 text-2xl font-bold text-white">Offline Library</h1>
        <p className="mb-8 text-zinc-400">
          {videos.length} video{videos.length !== 1 ? "s" : ""} saved for
          offline viewing
        </p>

        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {videos.map((video) => {
            const category =
              CATEGORY_MAP[video.category as keyof typeof CATEGORY_MAP];

            return (
              <article
                key={video.id}
                className="group overflow-hidden rounded-xl border border-white/5 bg-white/[0.03]"
              >
                <button
                  onClick={() => setPlaying(video)}
                  className="relative aspect-video w-full bg-zinc-900"
                >
                  <video
                    src={createOfflineVideoUrl(video.blob) + "#t=0.5"}
                    className="h-full w-full object-cover"
                    preload="metadata"
                    muted
                  />
                  <div className="absolute inset-0 flex items-center justify-center bg-black/30 opacity-0 transition-opacity group-hover:opacity-100">
                    <div className="flex h-12 w-12 items-center justify-center rounded-full bg-white/20 backdrop-blur-sm">
                      <Play className="h-5 w-5 fill-white text-white" />
                    </div>
                  </div>
                  <span className="absolute left-2 top-2 rounded-md bg-emerald-500/80 px-2 py-0.5 text-xs font-medium text-white">
                    Offline
                  </span>
                </button>

                <div className="flex items-center justify-between p-3">
                  <div className="min-w-0">
                    <h3 className="truncate text-sm font-medium text-white">
                      {video.title}
                    </h3>
                    <p className="text-xs text-zinc-500">
                      {category?.icon} {category?.label ?? video.category}
                    </p>
                  </div>
                  <button
                    onClick={() => handleRemove(video.id)}
                    className="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-lg text-zinc-500 transition-colors hover:bg-red-500/20 hover:text-red-400"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </article>
            );
          })}
        </div>
      </div>

      {playing && (
        <div
          className="fixed inset-0 z-[100] flex items-center justify-center bg-black/90 p-4 backdrop-blur-sm"
          onClick={() => setPlaying(null)}
        >
          <div
            className="relative w-full max-w-4xl"
            onClick={(e) => e.stopPropagation()}
          >
            <button
              onClick={() => setPlaying(null)}
              className="absolute -top-12 right-0 flex h-10 w-10 items-center justify-center rounded-full bg-white/10 text-white transition-colors hover:bg-white/20"
            >
              <X className="h-5 w-5" />
            </button>
            <video
              src={createOfflineVideoUrl(playing.blob)}
              controls
              autoPlay
              className="w-full rounded-xl"
            />
            <h2 className="mt-4 text-lg font-semibold text-white">
              {playing.title}
            </h2>
          </div>
        </div>
      )}
    </>
  );
}
