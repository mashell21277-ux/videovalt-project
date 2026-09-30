"use client";

import { useEffect, useState, FormEvent, useRef } from "react";
import {
  Link2,
  Trash2,
  LogOut,
  Lock,
  Loader2,
  Video as VideoIcon,
  Clapperboard,
  Upload,
  Radio,
  Grid3X3,
  UserPlus,
  MessageCircle,
  Users,
  Check,
  ImageIcon,
  Eye,
  EyeOff,
  Bell,
  Megaphone,
} from "lucide-react";
import type { Video } from "@/types/video";
import type { LiveProfile, LiveProfileWithLatest, ProfileMessage } from "@/types/live-profile";
import type { AppNotification } from "@/types/notification";
import { CATEGORIES } from "@/lib/constants";
import { formatFileSize } from "@/lib/utils";
import { getVideoPlaybackUrl } from "@/lib/video-url";
import { VideoCategory, VideoType } from "@prisma/client";

type PostMode = "link" | "file";

const fetchOpts: RequestInit = { credentials: "include" };

export function AdminPanel() {
  const [isAdmin, setIsAdmin] = useState<boolean | null>(null);
  const [password, setPassword] = useState("");
  const [loginError, setLoginError] = useState("");
  const [loggingIn, setLoggingIn] = useState(false);
  const [videos, setVideos] = useState<Video[]>([]);
  const [profiles, setProfiles] = useState<LiveProfileWithLatest[]>([]);
  const [selectedProfileId, setSelectedProfileId] = useState<string>("");
  const [notifications, setNotifications] = useState<AppNotification[]>([]);

  useEffect(() => {
    void checkAuth();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (profiles.length === 0) {
      setSelectedProfileId("");
      return;
    }
    if (!selectedProfileId || !profiles.some((p) => p.id === selectedProfileId)) {
      setSelectedProfileId(profiles[0].id);
    }
  }, [profiles, selectedProfileId]);

  async function checkAuth() {
    const res = await fetch("/api/auth/me", fetchOpts);
    const data = await res.json();
    setIsAdmin(data.isAdmin);
    if (data.isAdmin) {
      loadVideos();
      loadProfiles();
      loadNotifications();
    }
  }

  async function loadNotifications() {
    const res = await fetch("/api/notifications", fetchOpts);
    if (res.ok) setNotifications(await res.json());
  }

  async function loadVideos() {
    const res = await fetch("/api/videos", fetchOpts);
    setVideos(await res.json());
  }

  async function loadProfiles() {
    const res = await fetch("/api/live-profiles", fetchOpts);
    if (!res.ok) return;
    setProfiles(await res.json());
  }

  async function handleLogin(e: FormEvent) {
    e.preventDefault();
    setLoggingIn(true);
    setLoginError("");

    const res = await fetch("/api/auth/login", {
      ...fetchOpts,
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ password }),
    });

    if (res.ok) {
      setIsAdmin(true);
      setPassword("");
      loadVideos();
      loadProfiles();
      loadNotifications();
    } else {
      setLoginError("Invalid password");
    }
    setLoggingIn(false);
  }

  async function handleLogout() {
    await fetch("/api/auth/logout", { ...fetchOpts, method: "POST" });
    setIsAdmin(false);
    setVideos([]);
    setProfiles([]);
    setNotifications([]);
    setSelectedProfileId("");
  }

  async function handleDeleteNotification(id: string) {
    if (!confirm("Delete this notification?")) return;
    await fetch(`/api/notifications/${id}`, { ...fetchOpts, method: "DELETE" });
    loadNotifications();
  }

  async function handleToggleNotification(id: string, isActive: boolean) {
    await fetch(`/api/notifications/${id}`, {
      ...fetchOpts,
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ isActive: !isActive }),
    });
    loadNotifications();
  }

  async function handleDelete(id: string) {
    if (!confirm("Delete this video permanently?")) return;
    await fetch(`/api/videos/${id}`, { ...fetchOpts, method: "DELETE" });
    loadVideos();
    loadProfiles();
  }

  async function handleDeleteProfile(id: string) {
    if (!confirm("Delete this profile and all its messages? Videos will stay but lose the profile link."))
      return;
    await fetch(`/api/live-profiles/${id}`, { ...fetchOpts, method: "DELETE" });
    loadProfiles();
    loadVideos();
  }

  async function handleToggleVisibility(id: string, isVisible: boolean) {
    await fetch(`/api/live-profiles/${id}`, {
      ...fetchOpts,
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ isVisible: !isVisible }),
    });
    loadProfiles();
  }

  if (isAdmin === null) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-violet-500" />
      </div>
    );
  }

  if (!isAdmin) {
    return (
      <div className="mx-auto flex min-h-[60vh] max-w-md flex-col items-center justify-center px-4">
        <div className="w-full rounded-2xl border border-white/10 bg-white/[0.03] p-8">
          <div className="mb-6 flex flex-col items-center">
            <div className="mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-violet-500/20">
              <Lock className="h-7 w-7 text-violet-400" />
            </div>
            <h1 className="text-xl font-bold text-white">Admin Access</h1>
            <p className="mt-1 text-sm text-zinc-400">Only you can post videos</p>
          </div>
          <form onSubmit={handleLogin} className="space-y-4">
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Enter admin password"
              className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-3 text-white placeholder-zinc-500 outline-none focus:border-violet-500/50"
              required
            />
            {loginError && <p className="text-sm text-red-400">{loginError}</p>}
            <button
              type="submit"
              disabled={loggingIn}
              className="flex w-full items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-violet-500 to-fuchsia-500 py-3 font-medium text-white disabled:opacity-50"
            >
              {loggingIn ? <Loader2 className="h-5 w-5 animate-spin" /> : "Sign In"}
            </button>
          </form>
        </div>
      </div>
    );
  }

  const selectedProfile = profiles.find((p) => p.id === selectedProfileId);

  return (
    <div className="mx-auto max-w-5xl px-4 py-8">
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Admin Dashboard</h1>
          <p className="text-zinc-400">
            Create profiles, pick who to post as, manage live content
          </p>
        </div>
        <button
          onClick={handleLogout}
          className="flex items-center gap-2 rounded-lg bg-white/5 px-4 py-2 text-sm text-zinc-400 hover:bg-white/10 hover:text-white"
        >
          <LogOut className="h-4 w-4" />
          Logout
        </button>
      </div>

      {/* Broadcast notifications */}
      <div className="mb-10">
        <BroadcastNotificationForm onSuccess={loadNotifications} />
        {notifications.length > 0 && (
          <div className="mt-4 rounded-2xl border border-white/10 bg-white/[0.03] p-4">
            <h3 className="mb-3 flex items-center gap-2 text-sm font-semibold text-white">
              <Bell className="h-4 w-4 text-amber-400" />
              Sent to all users ({notifications.length})
            </h3>
            <div className="space-y-2">
              {notifications.map((n) => (
                <div
                  key={n.id}
                  className={`flex items-start gap-3 rounded-xl border p-3 ${
                    n.isActive
                      ? "border-amber-500/20 bg-amber-500/5"
                      : "border-white/5 bg-white/[0.02] opacity-60"
                  }`}
                >
                  <Megaphone className="mt-0.5 h-4 w-4 flex-shrink-0 text-amber-400" />
                  <div className="min-w-0 flex-1">
                    <p className="font-medium text-white">{n.title}</p>
                    <p className="mt-0.5 text-xs text-zinc-400 line-clamp-2">{n.body}</p>
                    <p className="mt-1 text-[10px] text-zinc-600">
                      {new Date(n.createdAt).toLocaleString()}
                      {n.isActive ? " · Live in app" : " · Hidden"}
                    </p>
                  </div>
                  <div className="flex flex-col gap-1">
                    <button
                      type="button"
                      title={n.isActive ? "Hide from app" : "Show in app"}
                      onClick={() => handleToggleNotification(n.id, n.isActive)}
                      className="flex h-7 w-7 items-center justify-center rounded-lg text-zinc-500 hover:bg-white/10 hover:text-white"
                    >
                      {n.isActive ? <Eye className="h-3.5 w-3.5" /> : <EyeOff className="h-3.5 w-3.5" />}
                    </button>
                    <button
                      type="button"
                      onClick={() => handleDeleteNotification(n.id)}
                      className="flex h-7 w-7 items-center justify-center rounded-lg text-zinc-600 hover:bg-red-500/20 hover:text-red-400"
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Create profile */}
      <div className="mb-10">
        <CreateProfileForm
          onSuccess={(newId) => {
            loadProfiles().then(() => {
              if (newId) setSelectedProfileId(newId);
            });
          }}
        />
      </div>

      {/* All profiles — pick one to post live */}
      <div className="mb-10">
        <ProfileGallery
          profiles={profiles}
          selectedId={selectedProfileId}
          onSelect={setSelectedProfileId}
          onDelete={handleDeleteProfile}
          onToggleVisibility={handleToggleVisibility}
        />
      </div>

      {/* Post forms */}
      <div className="mb-10 grid gap-6 lg:grid-cols-2">
        <PostForm
          variant="discover"
          onSuccess={() => {
            loadVideos();
            loadProfiles();
          }}
          icon={<Grid3X3 className="h-5 w-5 text-violet-400" />}
          title="Post to Discover / Reels"
          subtitle="Shows in Videos or Reels tabs — not in Live"
          accent="from-violet-500 to-fuchsia-500"
          isLive={false}
        />
        <PostForm
          variant="live"
          onSuccess={() => {
            loadVideos();
            loadProfiles();
          }}
          icon={<Radio className="h-5 w-5 text-red-400" />}
          title="Post Live Video"
          subtitle={
            selectedProfile
              ? `Posting as ${selectedProfile.name} — latest stays LIVE on top`
              : "Select a profile above first"
          }
          accent="from-red-500 to-rose-600"
          isLive={true}
          profileId={selectedProfileId}
          selectedProfile={selectedProfile}
        />
      </div>

      {profiles.length > 0 && (
        <div className="mb-10">
          <h2 className="mb-4 flex items-center gap-2 text-lg font-semibold text-white">
            <MessageCircle className="h-5 w-5 text-sky-400" />
            Profile Messages
          </h2>
          <div className="grid gap-4 lg:grid-cols-2">
            {profiles.map((p) => (
              <ProfileMessageAdmin key={p.id} profile={p} />
            ))}
          </div>
        </div>
      )}

      <div>
        <h2 className="mb-4 text-lg font-semibold text-white">
          All Content ({videos.length})
        </h2>
        {videos.length === 0 ? (
          <p className="text-zinc-500">Nothing posted yet</p>
        ) : (
          <div className="space-y-2">
            {videos.map((video) => {
              const src = getVideoPlaybackUrl(video);
              const profileName = profiles.find((p) => p.id === video.profileId)?.name;
              return (
                <div
                  key={video.id}
                  className="flex items-center gap-4 rounded-xl border border-white/5 bg-white/[0.03] p-3"
                >
                  {src ? (
                    <video
                      src={`${src}${video.sourceUrl ? "" : "#t=0.5"}`}
                      className="h-14 w-24 flex-shrink-0 rounded-lg object-cover"
                      preload="metadata"
                      muted
                    />
                  ) : (
                    <div className="flex h-14 w-24 flex-shrink-0 items-center justify-center rounded-lg bg-zinc-800">
                      <Link2 className="h-5 w-5 text-zinc-500" />
                    </div>
                  )}
                  <div className="min-w-0 flex-1">
                    <p className="truncate font-medium text-white">{video.title}</p>
                    <p className="truncate text-xs text-zinc-500">
                      {video.isLive ? "🔴 LIVE" : video.type} · {video.category}
                      {profileName ? ` · ${profileName}` : ""} ·{" "}
                      {video.sourceUrl ? "HD Link" : formatFileSize(video.fileSize)}
                    </p>
                  </div>
                  <button
                    onClick={() => handleDelete(video.id)}
                    className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-lg text-zinc-500 hover:bg-red-500/20 hover:text-red-400"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}

function CreateProfileForm({
  onSuccess,
}: {
  onSuccess: (newProfileId?: string) => void;
}) {
  const [name, setName] = useState("");
  const [handle, setHandle] = useState("");
  const [bio, setBio] = useState("");
  const [avatarUrl, setAvatarUrl] = useState("");
  const [avatarFile, setAvatarFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [creating, setCreating] = useState(false);
  const [error, setError] = useState("");
  const fileRef = useRef<HTMLInputElement>(null);

  function onPickAvatar(file: File | null) {
    setAvatarFile(file);
    if (preview) URL.revokeObjectURL(preview);
    setPreview(file ? URL.createObjectURL(file) : null);
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    if (!name.trim()) return;

    setCreating(true);
    setError("");

    const formData = new FormData();
    formData.append("name", name.trim());
    if (handle.trim()) formData.append("handle", handle.trim());
    if (bio.trim()) formData.append("bio", bio.trim());
    if (avatarFile) {
      formData.append("avatar", avatarFile);
    } else if (avatarUrl.trim()) {
      formData.append("avatarUrl", avatarUrl.trim());
    }

    const res = await fetch("/api/live-profiles", {
      ...fetchOpts,
      method: "POST",
      body: formData,
    });

    if (res.ok) {
      const data = await res.json();
      setName("");
      setHandle("");
      setBio("");
      setAvatarUrl("");
      onPickAvatar(null);
      onSuccess(data.id as string);
    } else {
      const data = await res.json().catch(() => ({}));
      setError(data.error || "Could not create profile");
    }
    setCreating(false);
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="rounded-2xl border border-sky-500/20 bg-white/[0.03] p-6"
    >
      <div className="mb-5 flex items-start gap-3">
        <UserPlus className="h-5 w-5 text-sky-400" />
        <div>
          <h2 className="text-lg font-semibold text-white">Create Live Profile</h2>
          <p className="text-xs text-zinc-500">Add a profile pic, name & bio — fake accounts for now</p>
        </div>
      </div>

      <div className="flex flex-col gap-5 sm:flex-row">
        {/* Profile pic */}
        <div className="flex flex-col items-center gap-3 sm:w-36">
          <button
            type="button"
            onClick={() => fileRef.current?.click()}
            className="group relative flex h-28 w-28 items-center justify-center overflow-hidden rounded-full border-2 border-dashed border-white/20 bg-white/5 transition hover:border-sky-500/50"
          >
            {preview ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={preview} alt="Preview" className="h-full w-full object-cover" />
            ) : (
              <div className="flex flex-col items-center gap-1 text-zinc-500 group-hover:text-sky-400">
                <ImageIcon className="h-8 w-8" />
                <span className="text-[10px] font-medium">Profile pic</span>
              </div>
            )}
            <div className="absolute inset-0 flex items-center justify-center bg-black/40 opacity-0 transition group-hover:opacity-100">
              <Upload className="h-6 w-6 text-white" />
            </div>
          </button>
          <input
            ref={fileRef}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={(e) => onPickAvatar(e.target.files?.[0] ?? null)}
          />
          <input
            type="url"
            value={avatarUrl}
            onChange={(e) => setAvatarUrl(e.target.value)}
            placeholder="Or paste image URL"
            className="w-full rounded-lg border border-white/10 bg-white/5 px-2 py-1.5 text-[11px] text-white outline-none focus:border-sky-500/50"
          />
        </div>

        <div className="min-w-0 flex-1 space-y-3">
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Display name (e.g. Sarah Streams)"
            className="w-full rounded-xl border border-white/10 bg-white/5 px-3 py-2.5 text-sm text-white outline-none focus:border-sky-500/50"
            required
          />
          <input
            type="text"
            value={handle}
            onChange={(e) => setHandle(e.target.value)}
            placeholder="Handle (optional, e.g. sarah-streams)"
            className="w-full rounded-xl border border-white/10 bg-white/5 px-3 py-2.5 text-sm text-white outline-none focus:border-sky-500/50"
          />
          <textarea
            value={bio}
            onChange={(e) => setBio(e.target.value)}
            placeholder="Short bio"
            rows={2}
            className="w-full resize-none rounded-xl border border-white/10 bg-white/5 px-3 py-2.5 text-sm text-white outline-none focus:border-sky-500/50"
          />
        </div>
      </div>

      {error && <p className="mt-3 text-xs text-red-400">{error}</p>}

      <button
        type="submit"
        disabled={creating || !name.trim()}
        className="mt-4 flex w-full items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-sky-500 to-cyan-500 py-2.5 text-sm font-medium text-white disabled:opacity-50 sm:w-auto sm:px-8"
      >
        {creating ? <Loader2 className="h-4 w-4 animate-spin" /> : <UserPlus className="h-4 w-4" />}
        {creating ? "Creating..." : "Create Profile"}
      </button>
    </form>
  );
}

function ProfileGallery({
  profiles,
  selectedId,
  onSelect,
  onDelete,
  onToggleVisibility,
}: {
  profiles: LiveProfileWithLatest[];
  selectedId: string;
  onSelect: (id: string) => void;
  onDelete: (id: string) => void;
  onToggleVisibility: (id: string, isVisible: boolean) => void;
}) {
  return (
    <div className="rounded-2xl border border-white/10 bg-white/[0.03] p-6">
      <div className="mb-5 flex items-start gap-3">
        <Users className="h-5 w-5 text-violet-400" />
        <div>
          <h2 className="text-lg font-semibold text-white">
            All Live Profiles ({profiles.length})
          </h2>
          <p className="text-xs text-zinc-500">
            Click to select for posting · eye icon toggles visible/hidden in the app
          </p>
        </div>
      </div>

      {profiles.length === 0 ? (
        <div className="rounded-xl border border-dashed border-white/10 py-12 text-center">
          <Users className="mx-auto mb-3 h-10 w-10 text-zinc-600" />
          <p className="text-sm text-zinc-500">No profiles yet — create one above</p>
        </div>
      ) : (
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {profiles.map((p) => {
            const selected = p.id === selectedId;
            const visible = p.isVisible !== false;
            return (
              <div
                key={p.id}
                className={`relative flex items-start gap-3 rounded-xl border p-4 transition ${
                  !visible ? "opacity-60" : ""
                } ${
                  selected
                    ? "border-red-500/50 bg-red-500/10 ring-1 ring-red-500/30"
                    : "border-white/10 bg-white/[0.02] hover:border-white/20 hover:bg-white/[0.04]"
                }`}
              >
                <button
                  type="button"
                  onClick={() => onSelect(p.id)}
                  className="flex min-w-0 flex-1 items-start gap-3 text-left"
                >
                  <ProfileAvatar profile={p} size="md" live={!!p.latestVideo && visible} />
                  <div className="min-w-0 flex-1 pr-8">
                    <div className="flex items-center gap-2">
                      <p className="truncate font-semibold text-white">{p.name}</p>
                      {selected && (
                        <span className="flex h-5 w-5 flex-shrink-0 items-center justify-center rounded-full bg-red-500">
                          <Check className="h-3 w-3 text-white" />
                        </span>
                      )}
                    </div>
                    <p className="truncate text-xs text-zinc-500">@{p.handle}</p>
                    <p className="mt-1.5 text-[11px] text-zinc-400">
                      {p.videoCount} videos · {p.messageCount} msgs
                      {p.latestVideo && visible ? " · 🔴 live" : ""}
                    </p>
                    <span
                      className={`mt-1.5 inline-flex items-center gap-1 rounded-md px-2 py-0.5 text-[10px] font-medium ${
                        visible
                          ? "bg-emerald-500/15 text-emerald-400"
                          : "bg-zinc-500/15 text-zinc-400"
                      }`}
                    >
                      {visible ? (
                        <>
                          <Eye className="h-3 w-3" /> Visible in app
                        </>
                      ) : (
                        <>
                          <EyeOff className="h-3 w-3" /> Hidden from app
                        </>
                      )}
                    </span>
                  </div>
                </button>
                <div className="absolute right-3 top-3 flex flex-col gap-1">
                  <button
                    type="button"
                    title={visible ? "Hide from app" : "Show in app"}
                    onClick={() => onToggleVisibility(p.id, visible)}
                    className={`flex h-7 w-7 items-center justify-center rounded-lg transition ${
                      visible
                        ? "text-emerald-400 hover:bg-emerald-500/20"
                        : "text-zinc-500 hover:bg-white/10 hover:text-zinc-300"
                    }`}
                  >
                    {visible ? <Eye className="h-3.5 w-3.5" /> : <EyeOff className="h-3.5 w-3.5" />}
                  </button>
                  <button
                    type="button"
                    title="Delete profile"
                    onClick={() => onDelete(p.id)}
                    className="flex h-7 w-7 items-center justify-center rounded-lg text-zinc-600 hover:bg-red-500/20 hover:text-red-400"
                  >
                    <Trash2 className="h-3.5 w-3.5" />
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

function ProfileAvatar({
  profile,
  size = "md",
  live = false,
}: {
  profile: Pick<LiveProfile, "name" | "avatarUrl">;
  size?: "sm" | "md" | "lg";
  live?: boolean;
}) {
  const dim =
    size === "sm" ? "h-10 w-10 text-sm" : size === "lg" ? "h-16 w-16 text-xl" : "h-12 w-12 text-base";
  const initial = profile.name.charAt(0).toUpperCase();

  const img = profile.avatarUrl ? (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={profile.avatarUrl}
      alt={profile.name}
      className={`${dim} flex-shrink-0 rounded-full object-cover`}
    />
  ) : (
    <div
      className={`${dim} flex flex-shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-violet-500 to-fuchsia-500 font-bold text-white`}
    >
      {initial}
    </div>
  );

  if (!live) {
    return <div className="ring-2 ring-white/10 rounded-full">{img}</div>;
  }

  return (
    <div className="rounded-full bg-gradient-to-br from-red-500 to-rose-600 p-[2px]">
      <div className="rounded-full bg-[#0A0A0F] p-[2px]">{img}</div>
    </div>
  );
}

function ProfileMessageAdmin({ profile }: { profile: LiveProfileWithLatest }) {
  const [authorName, setAuthorName] = useState(profile.name);
  const [content, setContent] = useState("");
  const [posting, setPosting] = useState(false);
  const [messages, setMessages] = useState<ProfileMessage[]>([]);

  useEffect(() => {
    void fetch(`/api/live-profiles/${profile.id}/messages`, fetchOpts)
      .then((r) => r.json())
      .then(setMessages);
  }, [profile.id]);

  async function handlePost(e: FormEvent) {
    e.preventDefault();
    if (!content.trim()) return;

    setPosting(true);
    const res = await fetch(`/api/live-profiles/${profile.id}/messages`, {
      ...fetchOpts,
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ authorName, content }),
    });

    if (res.ok) {
      const msg = await res.json();
      setMessages((prev) => [...prev, msg]);
      setContent("");
    }
    setPosting(false);
  }

  return (
    <div className="rounded-2xl border border-white/10 bg-white/[0.03] p-4">
      <div className="mb-3 flex items-center gap-2">
        <ProfileAvatar profile={profile} size="sm" />
        <div>
          <p className="text-sm font-medium text-white">{profile.name}</p>
          <p className="text-xs text-zinc-500">Post as host / moderator</p>
        </div>
      </div>

      <div className="mb-3 max-h-32 space-y-1.5 overflow-y-auto rounded-xl bg-black/20 p-2">
        {messages.length === 0 ? (
          <p className="px-2 py-4 text-center text-xs text-zinc-600">No messages yet</p>
        ) : (
          messages.slice(-6).map((m) => (
            <div key={m.id} className="rounded-lg bg-white/[0.04] px-2.5 py-1.5">
              <span className="text-xs font-semibold text-sky-300">{m.authorName}</span>
              <span className="text-xs text-zinc-400"> · </span>
              <span className="text-xs text-zinc-300">{m.content}</span>
            </div>
          ))
        )}
      </div>

      <form onSubmit={handlePost} className="flex gap-2">
        <input
          type="text"
          value={content}
          onChange={(e) => setContent(e.target.value)}
          placeholder="Write a message..."
          className="min-w-0 flex-1 rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-xs text-white outline-none focus:border-sky-500/50"
        />
        <button
          type="submit"
          disabled={posting || !content.trim()}
          className="rounded-xl bg-sky-500/20 px-3 py-2 text-xs font-medium text-sky-300 disabled:opacity-50"
        >
          Send
        </button>
      </form>
    </div>
  );
}

function PostForm({
  variant,
  onSuccess,
  icon,
  title,
  subtitle,
  accent,
  isLive,
  profileId,
  selectedProfile,
}: {
  variant: "discover" | "live";
  onSuccess: () => void;
  icon: React.ReactNode;
  title: string;
  subtitle: string;
  accent: string;
  isLive: boolean;
  profileId?: string;
  selectedProfile?: LiveProfileWithLatest;
}) {
  const [postMode, setPostMode] = useState<PostMode>("link");
  const [formTitle, setFormTitle] = useState("");
  const [description, setDescription] = useState("");
  const [sourceUrl, setSourceUrl] = useState("");
  const [category, setCategory] = useState<VideoCategory>("ENTERTAINMENT");
  const [type, setType] = useState<VideoType>("VIDEO");
  const [file, setFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState("");

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    if (!formTitle) return;
    if (isLive && !profileId) {
      setUploadError("Select a profile from the gallery above");
      return;
    }
    if (postMode === "link" && !sourceUrl.trim()) {
      setUploadError("Paste a video link");
      return;
    }
    if (postMode === "file" && !file) {
      setUploadError("Choose a video file");
      return;
    }

    setUploading(true);
    setUploadError("");

    const formData = new FormData();
    formData.append("title", formTitle);
    formData.append("description", description);
    formData.append("category", isLive ? "ENTERTAINMENT" : category);
    formData.append("type", type);
    formData.append("isLive", String(isLive));
    if (isLive && profileId) formData.append("profileId", profileId);

    if (postMode === "link") {
      formData.append("sourceUrl", sourceUrl.trim());
    } else if (file) {
      formData.append("file", file);
    }

    const res = await fetch("/api/videos", { ...fetchOpts, method: "POST", body: formData });

    if (res.ok) {
      setFormTitle("");
      setDescription("");
      setSourceUrl("");
      setFile(null);
      onSuccess();
    } else {
      const data = await res.json();
      setUploadError(data.error || "Post failed");
    }
    setUploading(false);
  }

  return (
    <form
      onSubmit={handleSubmit}
      className={`rounded-2xl border bg-white/[0.03] p-6 ${
        isLive ? "border-red-500/20" : "border-white/10"
      }`}
    >
      <div className="mb-4 flex items-start gap-3">
        {icon}
        <div className="min-w-0 flex-1">
          <h2 className="text-lg font-semibold text-white">{title}</h2>
          <p className="text-xs text-zinc-500">{subtitle}</p>
        </div>
      </div>

      {isLive && selectedProfile && (
        <div className="mb-4 flex items-center gap-3 rounded-xl border border-red-500/20 bg-red-500/5 px-3 py-2.5">
          <ProfileAvatar profile={selectedProfile} size="sm" live={!!selectedProfile.latestVideo} />
          <div className="min-w-0">
            <p className="text-xs text-zinc-500">Posting to</p>
            <p className="truncate text-sm font-semibold text-white">{selectedProfile.name}</p>
          </div>
        </div>
      )}

      {isLive && !profileId && (
        <p className="mb-3 rounded-xl border border-amber-500/30 bg-amber-500/10 px-3 py-2 text-xs text-amber-200">
          Create and select a profile above before posting live
        </p>
      )}

      <div className="mb-3 flex gap-2">
        {(["link", "file"] as PostMode[]).map((mode) => (
          <button
            key={mode}
            type="button"
            onClick={() => setPostMode(mode)}
            className={`flex flex-1 items-center justify-center gap-1.5 rounded-lg border py-2 text-xs font-medium ${
              postMode === mode
                ? isLive
                  ? "border-red-500/50 bg-red-500/20 text-red-300"
                  : "border-violet-500/50 bg-violet-500/20 text-violet-300"
                : "border-white/10 text-zinc-400"
            }`}
          >
            {mode === "link" ? <Link2 className="h-3.5 w-3.5" /> : <Upload className="h-3.5 w-3.5" />}
            {mode === "link" ? "HD Link" : "File"}
          </button>
        ))}
      </div>

      <div className="space-y-3">
        <input
          type="text"
          value={formTitle}
          onChange={(e) => setFormTitle(e.target.value)}
          placeholder="Title"
          className="w-full rounded-xl border border-white/10 bg-white/5 px-3 py-2.5 text-sm text-white outline-none focus:border-violet-500/50"
          required
        />

        {postMode === "link" ? (
          <input
            type="url"
            value={sourceUrl}
            onChange={(e) => setSourceUrl(e.target.value)}
            placeholder="Dropbox / direct HD link"
            className="w-full rounded-xl border border-white/10 bg-white/5 px-3 py-2.5 text-sm text-white outline-none focus:border-violet-500/50"
            required
          />
        ) : (
          <input
            type="file"
            accept="video/*"
            onChange={(e) => setFile(e.target.files?.[0] ?? null)}
            className="w-full rounded-xl border border-dashed border-white/20 bg-white/5 px-3 py-4 text-xs text-zinc-400 file:mr-3 file:rounded-lg file:border-0 file:bg-violet-500/20 file:px-3 file:py-1.5 file:text-violet-300"
            required
          />
        )}

        {!isLive && (
          <select
            value={category}
            onChange={(e) => setCategory(e.target.value as VideoCategory)}
            className="w-full rounded-xl border border-white/10 bg-white/5 px-3 py-2.5 text-sm text-white outline-none"
          >
            {CATEGORIES.map((c) => (
              <option key={c.key} value={c.key} className="bg-zinc-900">
                {c.icon} {c.label}
              </option>
            ))}
          </select>
        )}

        {!isLive && (
          <div className="flex gap-2">
            {(["VIDEO", "REEL"] as VideoType[]).map((t) => (
              <button
                key={t}
                type="button"
                onClick={() => setType(t)}
                className={`flex flex-1 items-center justify-center gap-1.5 rounded-lg border py-2 text-xs font-medium ${
                  type === t
                    ? "border-violet-500/50 bg-violet-500/20 text-violet-300"
                    : "border-white/10 text-zinc-400"
                }`}
              >
                {t === "VIDEO" ? <VideoIcon className="h-3.5 w-3.5" /> : <Clapperboard className="h-3.5 w-3.5" />}
                {t === "VIDEO" ? "Video" : "Reel"}
              </button>
            ))}
          </div>
        )}

        {postMode === "link" && (
          <p className="text-[11px] text-zinc-500">
            HD quality preserved — original link streamed with no re-encoding
          </p>
        )}
      </div>

      {uploadError && <p className="mt-2 text-xs text-red-400">{uploadError}</p>}

      <button
        type="submit"
        disabled={
          uploading ||
          (isLive && !profileId) ||
          (postMode === "link" ? !sourceUrl.trim() : !file)
        }
        className={`mt-4 flex w-full items-center justify-center gap-2 rounded-xl bg-gradient-to-r ${accent} py-2.5 text-sm font-medium text-white disabled:opacity-50`}
      >
        {uploading ? <Loader2 className="h-4 w-4 animate-spin" /> : icon}
        {uploading ? "Posting..." : isLive ? "Post Live" : "Post"}
      </button>
    </form>
  );
}

function BroadcastNotificationForm({ onSuccess }: { onSuccess: () => void }) {
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [sending, setSending] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    if (!title.trim() || !body.trim()) return;

    setSending(true);
    setError("");
    setSuccess(false);

    const res = await fetch("/api/notifications", {
      ...fetchOpts,
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title: title.trim(), body: body.trim() }),
    });

    if (res.ok) {
      setTitle("");
      setBody("");
      setSuccess(true);
      onSuccess();
      setTimeout(() => setSuccess(false), 3000);
    } else {
      const data = await res.json().catch(() => ({}));
      setError(data.error || "Could not send notification");
    }
    setSending(false);
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="rounded-2xl border border-amber-500/25 bg-white/[0.03] p-6"
    >
      <div className="mb-4 flex items-start gap-3">
        <Megaphone className="h-5 w-5 text-amber-400" />
        <div>
          <h2 className="text-lg font-semibold text-white">Send Notification to All Users</h2>
          <p className="text-xs text-zinc-500">
            Appears in the app bell icon for every user within ~45 seconds
          </p>
        </div>
      </div>

      <div className="space-y-3">
        <input
          type="text"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Notification title (e.g. New live stream tonight!)"
          className="w-full rounded-xl border border-white/10 bg-white/5 px-3 py-2.5 text-sm text-white outline-none focus:border-amber-500/50"
          required
        />
        <textarea
          value={body}
          onChange={(e) => setBody(e.target.value)}
          placeholder="Message for all users..."
          rows={3}
          className="w-full resize-none rounded-xl border border-white/10 bg-white/5 px-3 py-2.5 text-sm text-white outline-none focus:border-amber-500/50"
          required
        />
      </div>

      {error && <p className="mt-2 text-xs text-red-400">{error}</p>}
      {success && (
        <p className="mt-2 text-xs text-emerald-400">Sent! All app users will see it shortly.</p>
      )}

      <button
        type="submit"
        disabled={sending || !title.trim() || !body.trim()}
        className="mt-4 flex w-full items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-amber-500 to-orange-500 py-2.5 text-sm font-medium text-white disabled:opacity-50"
      >
        {sending ? <Loader2 className="h-4 w-4 animate-spin" /> : <Bell className="h-4 w-4" />}
        {sending ? "Sending..." : "Broadcast to All Users"}
      </button>
    </form>
  );
}
