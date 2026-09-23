# MedAID — Architectural Decisions

A lightweight decision log. Each entry records its **status**:

- **Accepted:** stated in `MedAID_Documentation/` or the project brief. Changing it requires
  updating the source documentation first.
- **Proposed:** a recommendation made during Phase 0 that has **not** been approved. It is
  not implemented until approved. Linked open questions (OQ-xx) are in
  `PROJECT_PLAN.md` §16.
- **Superseded:** replaced by a later entry (kept for history).

Add new entries at the end of the relevant section. Never renumber.

> **Status change (2026-09-17):** The project owner instructed "execute all phases 1 by 1"
> without answering the open questions. So **all proposals P-01…P-20 and the
> recommended answers to OQ-01…OQ-36 in `PROJECT_PLAN.md` §16 were adopted as working
> defaults** (see D-019). They are still easy to revisit. Any answer from the owner
> overrides them.

---

## Accepted decisions

### D-001 Documentation is the source of truth
- **Status:** Accepted
- **Decision:** `MedAID_Documentation/` (29 files) is authoritative. Its folder name differs
  from `documentation/` in the brief; the folder is used as-is unless renamed on approval
  (OQ-02).
- **Consequence:** Changes to architecture, API, or behavior must update these docs.

### D-002 Technology stack
- **Status:** Accepted (README, PROJECT_MANIFEST.json, brief)
- **Decision:** Flutter + Riverpod + GoRouter; Node.js + Express; MongoDB; JWT with
  email/username + password; Cloudinary; Firebase Cloud Messaging; OpenStreetMap;
  OpenRouteService (replaceable).
- **Consequence:** No alternative frameworks or state libraries without a recorded strong reason.

### D-003 Exactly three roles
- **Status:** Accepted
- **Decision:** `USER`, `VOLUNTEER`, `ADMIN`. There is no doctor role in V1.

### D-004 One global light theme
- **Status:** Accepted (docs 13, 15, 25)
- **Decision:** `lib/core/theme/app_theme.dart` is the only source of design tokens,
  including the SOS/emergency tokens. No per-role or per-screen theme files, and no
  hardcoded brand colors.

### D-005 Flutter architecture
- **Status:** Accepted (docs 11, 13, 14)
- **Decision:** Feature-first, role-aware structure with presentation → application
  (Riverpod) → domain → data layers and a `core/` for cross-cutting concerns. Widgets never
  call APIs. Repositories use a single centralized API client.

### D-006 Backend architecture
- **Status:** Accepted (docs 12, 13)
- **Decision:** routes → middleware → controllers → services → repositories → models, plus
  `validators/`, `integrations/`, `jobs/`, `utils/`, `config/`. Business rules live only in
  services.

### D-007 Assignment eligibility
- **Status:** Accepted (doc 07, brief)
- **Decision:** A volunteer receives an automatic assignment only if **all** of these hold:
  verificationStatus = APPROVED; operational status = ACTIVE (not BUSY, not OFFLINE); account
  not suspended; location present and not stale; no other open emergency or pending
  assignment.

### D-008 Two-minute acceptance timeout
- **Status:** Accepted (docs 02, 07, manifest)
- **Decision:** An assignment expires 2 minutes after dispatch. The emergency stays open,
  history is preserved, the next eligible volunteer is tried, and Admin is notified when no
  eligible volunteer remains. The value is a backend constant with default 2 minutes.

### D-009 Atomic acceptance
- **Status:** Accepted (docs 04, 07)
- **Decision:** Acceptance is a conditional atomic update. It succeeds only if the emergency
  is ASSIGNED, `assignedVolunteerId` matches the caller, and the assignment is still pending
  and unexpired. The volunteer then moves ACTIVE → BUSY, and resolution moves BUSY → ACTIVE.

### D-010 Routing abstraction
- **Status:** Accepted (docs 04, 07, 18)
- **Decision:** A `RoutingService` interface sits in front of OpenRouteService, with
  straight-line (haversine) fallback. The assignment engine never calls a provider directly.
  Dijkstra/A* apply only if a real road graph is introduced later.

### D-011 Document storage
- **Status:** Accepted (docs 08, 20, 22)
- **Decision:** Files go to Cloudinary. MongoDB stores metadata and references only.
  Cloudinary secrets exist only in backend environment variables.

### D-012 Camp visibility enforced by the backend
- **Status:** Accepted (docs 18, 21)
- **Decision:** A camp is visible to Users only when `isActive = true` **and**
  `startDateTime ≤ now ≤ endDateTime`. The rule is enforced in backend queries, not only in
  the UI.

### D-013 Localization
- **Status:** Accepted (doc 17)
- **Decision:** English, Hindi, and Marathi via ARB files under `lib/app/localization/`. The
  backend returns language-neutral error codes, which Flutter maps to localized messages.

### D-014 REST API contract
- **Status:** Accepted (doc 09)
- **Decision:** Base path `/api/v1` with a standard success/error envelope
  (`success`, `message`, `data` / `code`, `errors`). Every request is validated.
  `passwordHash` and secrets are never returned.

### D-015 Server-side authorization
- **Status:** Accepted (docs 02, 05, 22)
- **Decision:** Every protected endpoint checks authentication, then role, then
  ownership/resource access. Hiding things in the UI is never enough.

### D-016 Volunteer accounts are admin-created only
- **Status:** Accepted (docs 02, 20, brief). Resolves ambiguity C-08 in doc 05.
- **Decision:** Volunteers cannot self-register.

### D-017 Symptom checker is guidance only
- **Status:** Accepted (docs 01, 25)
- **Decision:** Output is presented as triage guidance, not a diagnosis. No invented medical
  facts, dosages, or protocols. Escalation wording is cautious.

### D-018 Working phase plan
- **Status:** Accepted (brief)
- **Decision:** The 13-phase plan (Phase 0–12) from the brief is the working plan. It
  supersedes the ordering in `26_IMPLEMENTATION_ROADMAP.md`, and a mapping is kept in
  `PROJECT_PLAN.md` §14. Each phase requires explicit approval before the next begins.

### D-019 Working defaults for open questions
- **Status:** Accepted as defaults (owner instruction to execute all phases, 2026-09-17)
- **Decision:** Every "Recommendation" in `PROJECT_PLAN.md` §16 is applied. Key ones:
  - `frontend/` + `backend/` layout
  - `git init` with no commits made by the assistant
  - app ID `com.medaid.app`
  - MongoDB Atlas for development, in-memory replica set for tests
  - Android first
  - press-and-hold SOS (1.5 s)
  - SOS allowed without a location fix (UNASSIGNED + admin escalation)
  - volunteer decline and optional IN_PROGRESS ("start") step
  - retry UNASSIGNED emergencies every 30 s
  - stale location 5 min, search radius 5 km, top 10 candidates, `foot-walking`
  - FCM + polling, with no WebSockets
  - documents: ID proof + first-aid certificate, PDF/JPG/PNG, ≤ 5 MB
- **Consequence:** Each default is implemented behind configuration or a small, isolated code path
  so it can change without restructuring.

### D-020 SDK Material library with go_router 17.x
- **Status:** Accepted (Phase 1 finding)
- **Context:** Flutter 3.44 introduced the standalone `material_ui` package, and go_router 18
  depends on it. `material_ui` 1.3.0 fails to compile on Flutter 3.44.0 (`@awaitNotRequired`
  is not exported by the SDK). flutter_map and flutter_riverpod still import the SDK's
  `package:flutter/material.dart`, and the compatibility bridge is itself deprecated.
- **Decision:** App code imports `package:flutter/material.dart`, and go_router is pinned to
  `^17.5.0`, which has no `material_ui` dependency.
- **Consequence:** One Material implementation across the app and its packages. Migrate later with
  `dart fix --apply --code=migrate_design_widgets` once the ecosystem moves.

### D-021 Jest runs with `--experimental-vm-modules`
- **Status:** Accepted (Phase 2 finding)
- **Context:** MongoDB Node driver 7.x loads its runtime adapter with a dynamic `import()`.
  Inside Jest's VM sandbox this fails silently, the handshake metadata is sent empty, and the
  server rejects the connection ("Missing required sub-document 'driver'").
- **Decision:** npm test scripts run Jest through
  `node --experimental-vm-modules node_modules/jest/bin/jest.js`.

### D-022 Database-level race guards
- **Status:** Accepted (implements D-009, P-04, P-08)
- **Decision:** In addition to conditional updates, partial unique indexes enforce:
  - one open emergency per user (`emergencies.isOpen`)
  - one active assignment per emergency (`emergencyAssignments.isActive`)
  - one active assignment per volunteer (`emergencyAssignments.isActive`)
- **Consequence:** Even a logic bug cannot double-assign. Services must keep `isOpen` and
  `isActive` in sync with the status fields.

### D-023 Volunteer location field layout
- **Status:** Accepted (small deviation from doc 08)
- **Decision:** `volunteers.currentLocation` is a pure GeoJSON Point. `locationUpdatedAt` and
  `locationAccuracy` are sibling fields instead of living inside the GeoJSON object, which keeps
  the 2dsphere index strict and valid. Doc 08 has been updated.

### D-024 One code format: 100-column lines
- **Status:** Accepted (Phase 9)
- **Decision:** Dart uses `formatter: page_width: 100` in `analysis_options.yaml`, matching the
  backend Prettier `printWidth: 100`. Both code bases were formatted in one mechanical pass
  (`dart format`, `prettier --write`). There were no behavior changes, and both test suites passed
  afterwards.
- **Consequence:** Future diffs contain only real changes. Run the formatters before finishing
  a change.

### D-025 Volunteer tracking lifecycle
- **Status:** Accepted (implements OQ-32's recommended default)
- **Decision:**
  - Tracking runs only while the volunteer is APPROVED and ACTIVE or BUSY, with the volunteer
    area open.
  - On Android it uses a foreground service with a visible notification. iOS uses background
    location mode.
  - Movement is reported at 25 m and coalesced to at most one update every 10 s. A 60 s
    heartbeat keeps a stationary volunteer fresh.
  - "Always"/background location permission is not requested.
- **Consequence:** Closing the app stops tracking, and the volunteer then stops receiving
  dispatches after the 5-minute staleness threshold. This fails safe, because nobody is
  dispatched from an old position.

### D-026 Notification text is rendered on the backend
- **Status:** Accepted (Phase 10)
- **Context:** The same event needs different words for each audience, and push text must
  exist server-side because the system tray shows it while the app is closed.
- **Decision:** `templates.js` holds a title and body per event and audience in en/hi/mr. Each
  record is rendered in the recipient's `preferredLanguage` when created, and the app displays
  the stored text.
- **Consequence:** One source of truth for notification wording, and push and in-app text always
  match. Changing the app language affects new notifications, not old ones.

### D-027 Firebase is configured through `--dart-define`
- **Status:** Accepted (Phase 10)
- **Decision:** The app passes `FirebaseOptions` from build-time defines instead of shipping
  `google-services.json`/`GoogleService-Info.plist`, and push is inactive unless
  `ENABLE_PUSH=true`. The backend enables FCM only when `FCM_SERVICE_ACCOUNT_PATH` is set.
- **Consequence:** The project builds, runs and demos with no Firebase account at all; in-app
  notifications work either way. These identifiers are not secrets (they ship in every Firebase
  app), unlike the backend service account, which stays out of version control.

### D-028 Android rings the emergency alert, and push is data-only
- **Status:** Accepted (Phase 12)
- **Context:** A dispatched volunteer has two minutes to answer and will not be watching the
  screen. An app-side looping tone only rings while the app is alive, which is exactly when the
  alert is least needed.
- **Decision:** The looping ring is the notification channel's own tone (`res/raw/emergency_ring.wav`)
  plus `FLAG_INSISTENT`, so Android repeats it until the alert is answered. The backend sends
  **data-only** pushes, and a background isolate raises the alert and answers its Accept/Decline
  buttons by calling the endpoints directly.
- **Rejected:** a `notification` block in the push. It makes Android draw the alert on its default
  channel and skip the app entirely when killed, losing both the ring and the buttons.
- **Consequence:** The alert behaves identically whether the app is open, backgrounded or killed,
  and `audioplayers` was dropped. Changing how the channel sounds needs a new channel id, because
  Android freezes a channel at creation — so volunteers reinstall once per such change. Do Not
  Disturb and OEM battery managers can still suppress it; neither is in the app's control.

### D-029 A timeline entry carries its reason, and only for allow-listed codes
- **Status:** Accepted (Phase 12)
- **Context:** The assignment engine retries, so an emergency's history legitimately repeats
  `ASSIGNING` and `UNASSIGNED`. Shown as bare status names they are indistinguishable and read
  as duplicated rows — a correct history looking like a bug.
- **Decision:** Each timeline entry carries a `reason` code, which the app localizes. The codes
  are allow-listed in the mapper; the stored `note` also holds free text (a user's cancellation
  reason, an admin's closing note), and that is never returned.
- **Rejected:** returning `note` as-is. It would put one person's words into every volunteer's
  and admin's view of the alert, which doc 19's data minimization exists to prevent.
- **Consequence:** A new backend reason must be added to the allow-list and to the app's enum to
  be shown; until then the entry simply shows no explanation rather than a wrong one.

### D-030 A transition that changes nothing writes no history
- **Status:** Accepted (Phase 12)
- **Context:** `emergencyRepository.transition` pushed a history entry unconditionally, and admin
  reassignment permits `ASSIGNING` in both `from` and `to`. Reassigning an emergency that was
  already being assigned therefore wrote a second identical row while nothing changed.
- **Decision:** When `from` contains `to`, the repository first attempts the transition against
  the other statuses and writes history; only if that does not match does it apply the remaining
  changes without a history entry.
- **Consequence:** Two queries instead of one, but only for the transitions that allow a
  self-move. The operation still succeeds and its other changes still apply, so callers are
  unaffected — what disappears is a row that said nothing the previous one did not.

---

## Proposed decisions (adopted as defaults, see D-019)

### P-01 Repository layout: `frontend/` + `backend/`
- **Status:** Proposed (OQ-01)
- **Context:** Doc 13 places Flutter in `frontend/`. The untouched scaffold currently sits at
  the root.
- **Proposal:** Move the scaffold into `frontend/`, create `backend/` beside it, and keep the
  docs and plan files at the root. Generated folders (`build/`, `.dart_tool/`) are recreated,
  not moved.
- **Consequence:** Matches the docs; Node and Flutter tooling stay separate.

### P-02 Separate volunteer state dimensions
- **Status:** Proposed (OQ-07; resolves C-03, C-04)
- **Proposal:**
  - `volunteers.verificationStatus`: `NOT_SUBMITTED → PENDING → APPROVED | REJECTED`
    (`REJECTED → PENDING` on resubmission)
  - `volunteers.status` (operational): `OFFLINE | ACTIVE | BUSY` (default OFFLINE)
  - `users.accountStatus`: `ACTIVE | SUSPENDED` (applies to all roles; enforced in auth
    middleware)
- **Consequence:** Each eligibility condition in D-007 is an independent, indexable check.
  Doc 03's combined list becomes a display mapping.

### P-03 One `users` collection for all roles
- **Status:** Proposed (resolves C-10)
- **Proposal:** All credentials live in `users` with `role ∈ {USER, VOLUNTEER, ADMIN}`.
  `volunteers` is a 1:1 extension linked by `userId`.
- **Consequence:** One login flow and one token model.

### P-04 Volunteer reservation during a pending assignment
- **Status:** Proposed (resolves C-05)
- **Proposal:** A volunteer stays `ACTIVE` while an assignment awaits acceptance, but
  `volunteers.currentAssignmentId` is set atomically (predicate `currentAssignmentId: null`).
  Eligibility requires it to be null. It is cleared on expiry, decline, or cancel, and kept
  through BUSY until resolution.
- **Consequence:** Two simultaneous SOS alerts cannot reserve the same volunteer.

### P-05 Sequential single-volunteer dispatch
- **Status:** Proposed
- **Proposal:** Dispatch one ranked volunteer at a time, as docs 07/24 imply, rather than
  broadcasting to several volunteers.
- **Consequence:** Easy to reason about and test. Worst-case time to reach the k-th candidate
  is about 2·(k−1) minutes, mitigated by decline (OQ-21).

### P-06 Database-driven scheduler, single instance
- **Status:** Proposed
- **Proposal:** An in-process interval job (about every 10 s) finds `PENDING` assignments
  with `expiresAt ≤ now` and expires each with a conditional update, then triggers
  reassignment. A second job retries `UNASSIGNED` emergencies (OQ-29). No in-memory
  per-assignment timers. Runs once at startup for recovery. Assumes one backend instance.
- **Consequence:** Survives restarts. A queue or worker can replace it later without API
  changes (doc 12).

### P-07 Candidate search then routing
- **Status:** Proposed (OQ-30, OQ-31)
- **Proposal:** Run `$geoNear` on eligible volunteers within a configurable radius and keep
  the top N. Then make one `RoutingService.matrix()` call (ORS Matrix, profile configurable)
  and rank by duration, then distance. On routing failure, rank by haversine and record
  `distanceSource = FALLBACK`.

### P-08 SOS idempotency
- **Status:** Proposed (A-08)
- **Proposal:** At most one open emergency per user. `POST /emergencies` accepts an
  `Idempotency-Key` header; a duplicate or second SOS returns the existing open emergency
  with `200` instead of creating a new one.

### P-09 Real-time updates: FCM + polling
- **Status:** Proposed (OQ-34)
- **Proposal:** No WebSocket library in V1. Push (FCM) triggers refreshes, and live screens
  (active emergency, volunteer dashboard, admin monitoring) poll every 5–10 s while visible.
- **Consequence:** No new dependency outside the documented stack.

### P-10 Single Flutter app with a shared login
- **Status:** Proposed (resolves C-16, C-17; OQ-03)
- **Proposal:** One app. The login screen is shared, the backend returns the role, and the
  GoRouter `redirect` sends each role to its own shell. Route access is guarded on the client
  **and** enforced on the server.

### P-11 Access + rotating refresh tokens
- **Status:** Proposed (OQ-10)
- **Proposal:** Short-lived access JWT (~15 min) and refresh token (~7 days) stored hashed in
  `refreshTokens`, rotated on use and revoked on logout or suspension. Tokens are kept in
  `flutter_secure_storage`. A dio interceptor refreshes transparently.

### P-12 Private document delivery
- **Status:** Proposed (resolves C-18)
- **Proposal:** Flutter uploads a multipart file to the backend. Multer (memory storage,
  size cap) checks the MIME allowlist and magic bytes, then uploads to Cloudinary with
  restricted (`authenticated`) delivery. MongoDB stores `publicId` and metadata. Admin views
  documents through short-lived signed URLs generated on request.

### P-13 Backend tooling
- **Status:** Proposed
- **Proposal:** Plain JavaScript (CommonJS, matching `server.js`/`app.js` in doc 13),
  Mongoose, Joi, bcryptjs, helmet, cors, express-rate-limit, pino, multer, cloudinary,
  firebase-admin, built-in `fetch`. Tests use Jest + Supertest + mongodb-memory-server.

### P-14 Flutter packages
- **Status:** Proposed
- **Proposal:** flutter_riverpod, go_router, flutter_localizations/intl, dio,
  flutter_secure_storage, shared_preferences, flutter_map + latlong2, geolocator,
  file_picker, url_launcher, firebase_core/firebase_messaging, flutter_local_notifications;
  mocktail for tests. Each is verified against Flutter 3.44 in Phase 1.

### P-15 No code generation initially
- **Status:** Proposed
- **Proposal:** Write Riverpod `Notifier`/`AsyncNotifier` classes by hand and use manual
  `fromJson`/`toJson`. Revisit only if the model count makes this error-prone.
- **Consequence:** Simpler build, easier for a student team to follow.

### P-16 Shared features and shared models
- **Status:** Proposed (resolves C-11)
- **Proposal:** Role-independent features (`auth`, `notifications`) live directly under
  `lib/features/`. Entities used by several roles (Emergency, MedicalCamp, Volunteer…) live in
  `lib/shared/models`. Role repositories call role-specific endpoints but share those models.
  That is not duplication, because each hits a different authorized endpoint.

### P-17 Additive folders beyond doc 13
- **Status:** Proposed
- **Proposal:**
  - Flutter: `core/location`, `core/notifications`, `core/widgets/{layout,chips,misc}`,
    `assets/fonts`, `l10n.yaml`
  - Backend: `services/{user,facility,admin}`, `scripts/` (seeds), `tests/`
- **Consequence:** Only additions; nothing in doc 13 changes. Doc 13 is updated once approved.

### P-18 Bundled fonts with Devanagari support
- **Status:** Proposed (OQ-12)
- **Proposal:** Bundle a font family that supports Latin and Devanagari as app assets. Do not
  fetch fonts at runtime, since networks at gatherings are congested.

### P-19 Localization keys everywhere
- **Status:** Proposed (resolves C-22)
- **Proposal:** Every user-visible string in every role uses ARB keys. Hindi and Marathi
  translations are mandatory in V1 for User screens and the shared auth screens; Volunteer and
  Admin keys may carry English values in `hi`/`mr` until translated.

### P-20 Routing and API keys stay on the backend
- **Status:** Proposed (OQ-27)
- **Proposal:** The volunteer response map gets route geometry and ETA from a backend
  endpoint (e.g. `GET /volunteers/me/emergencies/:id/route`) so the ORS key never ships in
  the app.

---

## Superseded decisions

*None yet.*

