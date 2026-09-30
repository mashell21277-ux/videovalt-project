# VideoVault

A modern video sharing app built with **Flutter** (mobile, web, desktop) and a **Next.js** backend API.

Only the admin can upload videos. Everyone else can browse by category, scroll reels, download, and watch offline.

## Features

- **Admin-only uploads** — Password-protected admin panel
- **4 category columns** — Entertainment, Education, Music, Sports
- **Reels feed** — Vertical scroll (TikTok-style)
- **Download & offline** — Save videos locally for offline playback
- **Cross-platform** — Android, iOS, Web, Windows

## Quick Start

### 1. Start XAMPP (MySQL + Apache)

Open **XAMPP Control Panel** → start **MySQL** and **Apache**.

### 2. Set up the database (phpMyAdmin)

- **phpMyAdmin:** http://localhost/phpmyadmin  
- Database name: **`videovault`**
- Import `database/videovault.sql` or run `npm run db:push`

`.env` connection (XAMPP default):
```
DATABASE_URL="mysql://root:@127.0.0.1:3306/videovault"
```

**PHP Admin dashboard:** http://localhost/video-app/php-admin/

### 3. Start the backend API

```bash
npm install
npm run db:push
npm run dev
```

The API runs at **http://localhost:3000**

### 4. Configure admin password

Edit `.env`:

```
ADMIN_PASSWORD="your-secure-password"
JWT_SECRET="your-random-secret-key"
```

### 5. Run the Flutter app

```bash
cd mobile
flutter pub get
flutter run
```

For **Android emulator**, update `mobile/lib/config/app_config.dart`:

```dart
static const String baseUrl = 'http://10.0.2.2:3000';
```

For a **physical device**, use your computer's local IP:

```dart
static const String baseUrl = 'http://192.168.x.x:3000';
```

## Admin Panel

Open the **Admin** tab in the Flutter app and sign in with your password from `.env`.

Default password: `changeme123`

## Project Structure

```
video app/
├── mobile/          → Flutter app (main UI)
│   └── lib/
│       ├── screens/     → Home, Reels, Admin, Offline
│       ├── services/    → API, Auth, Offline storage
│       └── widgets/     → Reusable UI components
├── src/app/api/     → Next.js REST API (backend)
├── prisma/          → Database schema
├── database/        → SQL for phpMyAdmin import
├── php-admin/       → PHP dashboard (uses same MySQL DB)
└── public/uploads/  → Video file storage
```

## Tech Stack

| Layer    | Technology                          |
|----------|-------------------------------------|
| Frontend | Flutter, Provider, GoRouter         |
| Backend  | Next.js API Routes                  |
| Database | MySQL (Prisma + phpMyAdmin)         |
| Offline  | Hive + local file storage           |
| Video    | video_player, chewie                |
