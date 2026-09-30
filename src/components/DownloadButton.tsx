"use client";

import { useState, useEffect } from "react";
import { Download, Check, Loader2 } from "lucide-react";
import {
  saveVideoOffline,
  isVideoOffline,
  removeOfflineVideo,
} from "@/lib/offline-storage";
import type { Video } from "@/types/video";
import { getVideoPlaybackUrl } from "@/lib/video-url";
import { cn } from "@/lib/utils";

interface DownloadButtonProps {
  video: Video;
  variant?: "default" | "compact";
}

export function DownloadButton({ video, variant = "default" }: DownloadButtonProps) {
  const [status, setStatus] = useState<"idle" | "downloading" | "downloaded">("idle");

  useEffect(() => {
    isVideoOffline(video.id).then((offline) => {
      if (offline) setStatus("downloaded");
    });
  }, [video.id]);

  async function handleDownload() {
    if (status === "downloaded") {
      await removeOfflineVideo(video.id);
      setStatus("idle");
      return;
    }

    setStatus("downloading");
    try {
      const response = await fetch(getVideoPlaybackUrl(video));
      const blob = await response.blob();

      await saveVideoOffline({
        id: video.id,
        title: video.title,
        category: video.category,
        type: video.type,
        blob,
      });

      setStatus("downloaded");
    } catch {
      setStatus("idle");
    }
  }

  const isCompact = variant === "compact";

  return (
    <button
      onClick={handleDownload}
      disabled={status === "downloading"}
      className={cn(
        "flex items-center justify-center gap-2 rounded-lg font-medium transition-all",
        isCompact ? "h-9 w-9" : "px-4 py-2 text-sm",
        status === "downloaded"
          ? "bg-emerald-500/20 text-emerald-400 hover:bg-emerald-500/30"
          : "bg-white/10 text-white hover:bg-white/20",
        status === "downloading" && "cursor-wait opacity-70"
      )}
      title={
        status === "downloaded"
          ? "Remove offline copy"
          : status === "downloading"
            ? "Downloading..."
            : "Save for offline"
      }
    >
      {status === "downloading" ? (
        <Loader2 className="h-4 w-4 animate-spin" />
      ) : status === "downloaded" ? (
        <Check className="h-4 w-4" />
      ) : (
        <Download className="h-4 w-4" />
      )}
      {!isCompact && (
        <span>
          {status === "downloaded"
            ? "Saved"
            : status === "downloading"
              ? "Saving..."
              : "Download"}
        </span>
      )}
    </button>
  );
}
