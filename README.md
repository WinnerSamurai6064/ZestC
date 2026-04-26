# ⚡ ZestChat

A modern messaging PWA built with **Flutter Web** (frontend) + **Vercel Serverless** (backend) + **Neon PostgreSQL** (database).

**Aesthetic:** Lime green glassmorphism, dark base, WhatsApp-meets-Instagram DM vibes.

---

## Stack

| Layer | Tech |
|-------|------|
| Frontend | Flutter 3.22+ (Web / PWA) |
| Backend | Vercel Serverless Functions (Node.js) |
| Database | Neon PostgreSQL (serverless Postgres) |
| Image Storage | Cloudflare R2 / AWS S3 compatible |
| Auth | JWT (bcryptjs hashed passwords) |
| Deploy | GitHub → Vercel (CI via GitHub Actions) |

---

## Project Structure

```
zestchat/
├── lib/                    # Flutter app
│   ├── main.dart
│   ├── theme/theme.dart    # Lime green design system
│   ├── models/models.dart  # User, Chat, Message
│   ├── services/
│   │   ├── api_service.dart
│   │   └── chat_provider.dart
│   ├── widgets/widgets.dart # GlassCard, ZestAvatar, MessageBubble, ZestButton
│   └── screens/
│       ├── auth_screen.dart
│       ├── home_screen.dart
│       ├── chat_screen.dart
│       ├── search_screen.dart
│       └── profile_screen.dart
├── web/
│   ├── index.html          # Custom splash loader
│   └── manifest.json       # PWA manifest
├── api/                    # Vercel serverless functions
│   ├── _db.js              # Neon DB pool + schema init
│   ├── _auth.js            # JWT helpers + CORS
│   ├── auth/
│   │   ├── register.js     # POST /api/auth/register
│   │   └── login.js        # POST /api/auth/login
│   ├── users/
│   │   └── [action].js     # GET /api/users/search, PATCH /api/users/me
│   ├── chats/
│   │   ├── index.js        # GET/POST /api/chats
│   │   └── [chatId].js     # GET/POST/PATCH /api/chats/[chatId]
│   └── upload.js           # POST /api/upload
├── .github/workflows/deploy.yml
├── vercel.json
├── package.json            # Node deps for API
└── pubspec.yaml            # Flutter deps
```

---

## Setup Guide

### 1. Neon PostgreSQL

1. Go to [neon.tech](https://neon.tech) → create a free project
2. Copy your connection string: `postgresql://user:pass@ep-xxx.neon.tech/neondb?sslmode=require`
3. Tables are **auto-created** on first API call via `initDb()`

### 2. Image Storage (Cloudflare R2)

1. Go to Cloudflare Dashboard → R2 → Create bucket (`zestchat-media`)
2. Create API token with R2 read/write permissions
3. Note your endpoint: `https://<account-id>.r2.cloudflarestorage.com`

> **Alternative**: Use any S3-compatible service (Backblaze B2, MinIO, AWS S3)

### 3. Vercel

1. Install Vercel CLI: `npm i -g vercel`
2. From project root: `vercel login && vercel`
3. Add environment variables in Vercel Dashboard → Settings → Environment Variables:

```
DATABASE_URL=postgresql://...
JWT_SECRET=your_super_secret_key_here
STORAGE_ENDPOINT=https://<account>.r2.cloudflarestorage.com
STORAGE_BUCKET=zestchat-media
STORAGE_KEY=your_r2_access_key
STORAGE_SECRET=your_r2_secret_key
```

4. Or use Vercel secrets for CI:
```bash
vercel secrets add database_url "postgresql://..."
vercel secrets add jwt_secret "your_secret"
# etc.
```

### 4. GitHub Actions (Auto Deploy)

Add these secrets to your GitHub repo → Settings → Secrets:

```
VERCEL_TOKEN       # From vercel.com/account/tokens
VERCEL_ORG_ID      # From vercel.json or project settings
VERCEL_PROJECT_ID  # From .vercel/project.json after first deploy
```

Every push to `main` will:
1. Build Flutter web (`flutter build web --release`)
2. Deploy everything to Vercel production

### 5. Local Development

```bash
# Flutter
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api

# Vercel dev (runs API locally)
npm install
vercel dev
```

---

## API Routes

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/auth/register` | Create account |
| POST | `/api/auth/login` | Sign in, get JWT |
| GET | `/api/users/search?q=` | Search users |
| PATCH | `/api/users/me` | Update profile |
| GET | `/api/chats` | List chats |
| POST | `/api/chats` | Create/get DM |
| GET | `/api/chats/[id]?page=` | Get messages |
| POST | `/api/chats/[id]` | Send message |
| PATCH | `/api/chats/[id]` | Mark as read |
| POST | `/api/upload` | Upload image |

---

## Features

- 🔐 JWT authentication (register + login)
- 💬 Real-time-style messaging (3s polling, upgradeable to WebSocket)
- 🖼️ Image sharing with S3-compatible storage
- 📱 PWA installable on mobile
- 🟢 Online status + last seen
- ✅ Message read receipts (sent → delivered → read)
- 🔍 User search
- 👤 Profile editing
- 🌙 Pure dark theme with lime green glass UI
- 📲 WhatsApp-style chat bubbles + Instagram-style story row

---

## Extending

- **Real-time**: Replace polling in `chat_provider.dart` with `web_socket_channel` pointing to a Vercel Edge Function or a separate WS server (Fly.io, Railway)
- **Push notifications**: Add Firebase Cloud Messaging + a `/api/push` endpoint
- **Group chats**: Extend `chat_participants` to allow 3+ members
