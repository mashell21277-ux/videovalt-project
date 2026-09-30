export function normalizeVideoUrl(url: string): string {
  try {
    const parsed = new URL(url.trim());
    if (parsed.hostname.includes("dropbox.com")) {
      parsed.searchParams.set("dl", "1");
    }
    return parsed.toString();
  } catch {
    return url.trim();
  }
}

export function getVideoPlaybackUrl(video: {
  filename: string | null;
  sourceUrl: string | null;
}): string {
  if (video.sourceUrl) return video.sourceUrl;
  if (video.filename) return `/uploads/${video.filename}`;
  return "";
}

export function isValidVideoUrl(url: string): boolean {
  try {
    const parsed = new URL(url.trim());
    return parsed.protocol === "http:" || parsed.protocol === "https:";
  } catch {
    return false;
  }
}
