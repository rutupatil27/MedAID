# Deploying MedAID

Two independent things, in the order they are easiest to do:

1. **[Firebase Cloud Messaging](#1-firebase-cloud-messaging)** — so an emergency reaches a
   volunteer whose app is closed. Free, no card.
2. **[The backend on Render](#2-the-backend-on-render)** — so the app talks to a real server
   instead of your laptop.
3. **[Building the app](#3-building-the-app)** — one command that bakes both in.

Neither is required to run MedAID. Without FCM the app still alerts whenever it is open; without
a deployment it still runs against your laptop over Wi-Fi. Read
[Running it](README.md#running-it) first if you have not got that far.

---

## 1. Firebase Cloud Messaging

### What it buys you

The emergency alert rings, keeps ringing, and carries Accept/Decline buttons — all of that already
works with no Firebase at all, **as long as the app is running**. What it cannot do is reach a
volunteer who swiped the app away or whose phone killed it in the background. Nothing of ours is
running then, so nothing can poll.

FCM's only job here is to wake the phone. Once woken, a background isolate raises the same alert on
the same channel (see [doc 18](MedAID_Documentation/18_MAPS_AND_LOCATION.md)).

### Cost

Free. Cloud Messaging is on Firebase's Spark plan with no message limit, no credit card and no
billing account. You are not signing up for anything that later charges you.

### Step 1 — Create the project

1. Go to [console.firebase.google.com](https://console.firebase.google.com) and sign in.
2. **Create a project**. Any name; `medaid` is fine.
3. Google Analytics is offered — **skip it**. It is unrelated and adds consent obligations.

### Step 2 — Register the Android app

1. On the project overview, press the **Android** icon.
2. **Android package name:** `com.medaid.app` — this must match exactly. It comes from
   [`frontend/android/app/build.gradle.kts`](frontend/android/app/build.gradle.kts).
3. Nickname and the debug signing certificate can be left blank.
4. Firebase offers you **`google-services.json`**. You do not need it: this project configures
   Firebase from build-time values instead of shipping that file
   ([D-027](DECISIONS.md)), and the Google Services Gradle plugin is deliberately not applied.
   Download it anyway if you like — it is a convenient place to read the values in step 3 from.

### Step 3 — Collect the four app values

**Project settings** (the gear, top left) **→ General**:

| Firebase calls it | Build value |
|---|---|
| Project ID | `FIREBASE_PROJECT_ID` |
| Web API key | `FIREBASE_API_KEY` |
| App ID for your Android app (`1:123…:android:abc…`) | `FIREBASE_ANDROID_APP_ID` |
| **Cloud Messaging** tab → Sender ID | `FIREBASE_MESSAGING_SENDER_ID` |

These are identifiers, not secrets — they ship inside every Firebase app on the store. Committing
them is harmless. The next step is the one that matters.

### Step 4 — Get the service-account key (the actual secret)

**Project settings → Service accounts → Generate new private key.** A JSON file downloads.

This credential can send push to every user of your project. Treat it like a password:

- It never goes in the app, and never in git. `.gitignore` already blocks `*service-account*.json`
  and `backend/secrets/`.
- **Locally:** put it at `backend/secrets/fcm.json` and set
  `FCM_SERVICE_ACCOUNT_PATH=./secrets/fcm.json` in `backend/.env`.
- **On Render:** upload it as a Secret File (step 2.4 below).

Leave `FCM_SERVICE_ACCOUNT_PATH` blank and the backend uses a no-op push provider — everything
else works, so this is a safe way to defer the whole thing.

### Step 5 — Verify it on a real phone

Push is the one part of this system that cannot be proven by tests, because it depends on Google's
servers and on the phone's own power management. After building the app (section 3), sign in on the
phone — that registers its device token — and then, from `backend/`:

```bash
npm run push:test volunteer@example.com
```

A notification should appear on the phone, sounding the alert tone once. It carries no buttons and
does not loop, so a test never looks like a real emergency. The script says which step failed if
one does: push not configured, no account, no registered device, or a token FCM rejected.

Run it again with the **app swiped away**. That is the case nothing else can check: it proves
Android wakes the background isolate for a terminated app.

**If the alert arrives with the app open but not when it is killed**, the likely cause is that
Android's native Firebase SDK has no configuration of its own to start from — the build-time
values reach Dart, but a terminated app is started by Android before Dart exists. The fix is to
add `google-services.json` and the Google Services Gradle plugin, which supersedes D-027 for
Android. Ask and it is a small change; it is left out until proven necessary because it puts a
generated file into the build that D-027 was written to avoid.

### What can still silence an alert

Worth telling volunteers, because neither is a bug you can fix in code:

- **Do Not Disturb**, unless alarms are allowed through.
- **Battery managers on some Android skins** — Xiaomi, Oppo, Vivo, Realme — block background
  wake-ups until the app is allowed to "autostart". This affects every app that does this,
  including ordinary calling apps.

---

## 2. The backend on Render

### Before you start

- The repository has **no commits yet**. Render deploys from GitHub, so commit and push first.
  `backend/.env` and the service-account JSON are already gitignored; check `git status` before the
  first push regardless.
- A **MongoDB Atlas** cluster. The assignment engine uses transactions, which need a replica set —
  Atlas gives you one; a plain local `mongod` does not.

### Know this about the free tier

Free Render instances **spin down after 15 minutes without traffic**, and this backend runs its
own scheduler in-process ([`backend/src/jobs/index.js`](backend/src/jobs/index.js)):

- `assignment-scan` every 10 s — fires the 2-minute acceptance timeouts and reassigns
- `unassigned-retry` every 30 s — retries emergencies still waiting for a volunteer

While the instance sleeps, **neither runs**. A volunteer who ignores an alert is never timed out
and the emergency is never reassigned until some request happens to wake the server. Cold start is
then roughly 50 seconds, which an SOS press would sit through.

| Option | Cost | Honest assessment |
|---|---|---|
| **Starter instance** | $7/mo | Never sleeps. The only option where the timeout logic is actually correct. |
| **Keep-alive ping** (e.g. cron-job.org hitting `/api/v1/health` every 10 min) | free | Works in practice, but deliberately defeats a limit the free tier exists to enforce, and cold starts still happen. |
| **Free, as-is** | free | Fine for a demo you wake up two minutes beforehand. Not for anything left running. |

### Step 1 — Atlas network access

**Atlas → Network Access → Add IP Address → Allow access from anywhere (`0.0.0.0/0`).**

Free Render instances have no fixed outbound IP, so an allow-list cannot work. This is the same
`tlsv1 alert internal error` you get locally when your own IP is not listed.

Your connection string must include the database name:

```
mongodb+srv://USER:PASSWORD@cluster.mongodb.net/medaid?retryWrites=true&w=majority
```

### Step 2 — Create the service

The repository ships a [`render.yaml`](render.yaml) blueprint, so Render fills in the settings and
prompts for the secrets:

**Render dashboard → New → Blueprint → pick the repository.**

To do it by hand instead, create a Web Service with:

| Setting | Value |
|---|---|
| Root Directory | `backend` |
| Build Command | `npm ci` |
| Start Command | `npm start` |
| Health Check Path | `/api/v1/health` |

### Step 3 — Environment variables

The blueprint sets the rest; these are the ones it asks you for:

| Variable | Notes |
|---|---|
| `MONGODB_URI` | From step 1, including `/medaid`. |
| `CLOUDINARY_CLOUD_NAME` / `_API_KEY` / `_API_SECRET` | Blank disables volunteer document upload. |
| `ORS_API_KEY` | Blank falls back to straight-line ETAs, marked as estimates in the app. |

Two that the blueprint sets for you, and why they matter:

- **`TRUST_PROXY=1`** — Render sits behind a proxy. Without this, `express-rate-limit` sees the
  proxy's IP for every request, so one person hitting the auth limit locks out everyone.
- **`JWT_ACCESS_SECRET`** — generated by Render, so your laptop's secret never reaches production.
  If the service fails to boot complaining that it is too short, set it manually:
  `node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"`.

### Step 4 — The Firebase key, if you did section 1

**The blueprint will not ask you for this.** Blueprints can only prompt for environment variables,
and the Firebase key is a *secret file* — a multi-line JSON document that env vars would mangle.
`FCM_SERVICE_ACCOUNT_PATH` is fixed in [`render.yaml`](render.yaml), so there is nothing to prompt
for; the file is uploaded by hand once the service exists.

**Service → Environment → Secret Files → Add Secret File**, filename `fcm.json`, contents pasted
from the downloaded JSON. It is mounted at `/etc/secrets/fcm.json`, where the blueprint already
points.

Deploying before uploading it is safe: push failures are caught and logged
(`notification.service.js`), so the API keeps working and only push is missing.

### Step 5 — Create the first admin

There is no admin account until you make one. From **Render → your service → Shell**:

```bash
npm run seed:admin
```

It reads `ADMIN_SEED_EMAIL`, `ADMIN_SEED_USERNAME` and `ADMIN_SEED_PASSWORD`, so set those first.
Change the password after the first login.

### Step 6 — Check it

```bash
curl https://YOUR-SERVICE.onrender.com/api/v1/health
```

---

## 3. Building the app

Copy [`frontend/dart_defines.example.json`](frontend/dart_defines.example.json) to
`dart_defines.json` and fill in the four Firebase values with `"ENABLE_PUSH": true`.

**Leave `API_BASE_URL` empty until you have actually deployed.** Empty means a debug build falls
back to `AppConfig.devApiBaseUrl` — your laptop — so you can set up push against the backend you
already have running:

```bash
flutter run --dart-define-from-file=dart_defines.json
```

A made-up URL is worse than none: `*.onrender.com` resolves for every name, so the app hangs on a
service that does not exist rather than failing clearly. Once the service is live, put its real
address in and build:

```bash
cd frontend
flutter build apk --release --dart-define-from-file=dart_defines.json
```

The APK lands in `build/app/outputs/flutter-apk/app-release.apk`. Share the file directly;
testers need "install from unknown sources" enabled.

Notes:

- **HTTPS is required in release builds.** Render gives you HTTPS, so this is free. A release
  build with no `API_BASE_URL` trips an assert rather than silently pointing at your laptop.
- **Reinstall rather than upgrade in place** when the notification channel id changes. Android
  freezes a channel's sound at creation, so an upgraded install keeps the old behaviour. The
  current id is in
  [`local_notifier.dart`](frontend/lib/core/notifications/local_notifier.dart).
- **Push does nothing without `ENABLE_PUSH: true`** *and* the backend service-account file. Both
  ends have to be configured; either alone leaves you with in-app alerts only.
