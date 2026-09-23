# MedAID — Development Status

**Last updated:** 2026-09-20
**Current phase:** All 12 phases complete
**Mode:** Executing all phases in order, as instructed by the owner ("execute all phases 1 by 1").
Open questions use the recommended defaults (DECISIONS D-019).

---

## Completed work

### Phase 0: Analysis & plan ✅
- `PROJECT_PLAN.md`, `DECISIONS.md`, and this file.
- Documentation review: 22 contradictions and 36 open questions.

### Phase 1: Project foundation ✅
- Moved the Flutter scaffold into `frontend/` (P-01) and deleted generated caches.
- Changed the app ID to `com.medaid.app` on Android, iOS, macOS, and Linux. The Android label is now "MedAID".
- Ran `git init` (branch `main`, no commits) and added a root `.gitignore`.
- Flutter dependencies: flutter_riverpod 3.4, go_router 17.5 (D-020), dio, flutter_secure_storage, shared_preferences, flutter_map, latlong2, geolocator, file_picker, url_launcher, intl, mocktail.
- Bundled Poppins fonts, which cover Latin and Devanagari (P-18).
- `lib/core/theme/app_theme.dart` is the single design-token source. It holds colors, emergency tokens, spacing, radii, sizes, durations, tones, `AppPalette`, and component themes.
- gen-l10n is configured with ARB files for en/hi/mr: common strings and localized messages for backend error codes.
- `localeProvider` persists the chosen language and falls back to the device language.
- Centralized `ApiClient` (dio). It unwraps the response envelope, maps errors to `ApiException` codes, and sends an `Accept-Language` header.
- GoRouter skeleton and splash screen. Replaced the counter demo and its test.
- Backend tooling: `package.json`, ESLint, Prettier, `.env.example`.
- Verification: `flutter analyze` reports no issues; `flutter test` passes 3/3.

### Phase 2: Backend foundation ✅
- Express 5 app with helmet, an explicit CORS allowlist, rate limiting, a JSON body limit, and pino logging with secret redaction.
- Env validation with Joi. MongoDB connection with a transaction capability check and a `withTransaction` helper.
- `AppError`, error codes, success/error response envelopes, `validate` middleware, `notFound` and `errorHandler`.
- `GET /api/v1/health`.
- All models with indexes, including DB-level race guards (D-022).
- Scheduler shell for background jobs (P-06).
- Test harness: Jest, Supertest, and an in-memory MongoDB replica set (D-021).
- Verification: ESLint is clean; `npm test` passes 8/8. A smoke test booted `server.js` and got 200 from `/health`.

### Phase 3: Authentication & role system ✅
- **Backend:**
  - Register (USER only), login by email or username, and bcrypt hashing with timing equalization.
  - JWT access tokens. Refresh tokens rotate, are stored hashed, and are revoked as a family if reused. A 20-second grace window covers lost responses.
  - Logout, and change-password, which ends all other sessions.
  - The `authenticate` middleware reloads account state on every request, so suspension and password changes apply immediately.
  - `authorize(roles)` enforces `PASSWORD_CHANGE_REQUIRED`.
  - `GET/PATCH /users/me`, with a medical profile for USER accounts. `npm run seed:admin` creates the first admin.
- **Flutter:**
  - `TokenStorage` (secure storage) and the `AuthInterceptor`. Concurrent 401s share a single refresh, and an offline device keeps its session.
  - `authProvider` restores the session.
  - The pure `resolveRedirect` role guard with GoRouter `refreshListenable`.
  - Splash, login, register, and change-password screens, plus a temporary role home placeholder.
- **Docs:** doc 09 (auth endpoints and session shape) and doc 23 (new error codes).
- **Verification:** backend 28/28, Flutter 29/29.

### Phase 4: Global Flutter UI system ✅
- **Widget library in `lib/core/widgets`:**
  - Layout: AppScaffold, AppHeader, SectionHeader, BottomNavBar, RoleShellScaffold.
  - Buttons: PrimaryButton, SecondaryButton, DangerButton, and EmergencyButton (press-and-hold SOS with a semantic-tap fallback).
  - Inputs and chips: SearchField, StatusChip.
  - Cards: AppCard, StatCard, FacilityCard, MedicalCampCard, EmergencyCard, VolunteerStatusCard, DocumentUploadTile.
  - States: LoadingView, ErrorView, EmptyStateView, AsyncValueView.
  - Dialogs: ConfirmationDialog, AppSnackbar.
  - Misc: ProfileAvatar, PermissionPrompt, LanguageSelector.
  - Maps: LocationMap (flutter_map, OSM attribution, injectable tile provider) and the MapMarker abstraction.
- **Architecture rules test:** exactly one theme file, no hardcoded colors, no literal `Text('...')` strings, presentation code never imports dio or ApiClient, and no `material_ui`.
- **Verification:** `flutter analyze` is clean; Flutter 61/61.

### Phase 5: User module ✅
- **Backend:**
  - Symptom checker. Rule-based and conservative, with content in en/hi/mr marked **PENDING_CLINICAL_REVIEW**. Vulnerable groups and long-lasting symptoms are never left at ROUTINE.
  - Nearby facilities: hospitals plus only the camps that are currently valid, using `$geoNear` distance ordering. Camp and hospital details.
  - SOS creation is idempotent. It uses the `Idempotency-Key` header, one open emergency per user (DB index), and concurrency-safe creation, and works without a location fix.
  - Paged history, owner-only detail (404 for other users), and cancellation that releases a BUSY volunteer.
  - Stable `assignmentService` and `notificationService` interfaces, to be implemented in Phases 8 and 10.
- **Flutter:**
  - User shell with 4 tabs.
  - Home with the SOS hold button, active-alert card, and quick actions.
  - SOS sending screen: best-effort location, retries reuse the idempotency key, and it can call 112.
  - Live emergency status: polling, responder and ETA only after acceptance, timeline, and cancel with confirmation.
  - Alert history.
  - Symptom checker and result: SOS, call, and nearest-facility actions plus the disclaimer.
  - Nearby facilities list and map, with a location-permission prompt, and facility details with call and directions.
  - Profile: details, medical info with an explicit consent switch, language, and change password.
  - Shared account controller, location service abstraction, formatters, and external actions.
- **Bugs found by tests and fixed:**
  - The status row overflowed with long labels.
  - flutter_map's attribution row overflowed on narrow maps; replaced with our own ellipsizing attribution.
- **Docs:** doc 09 now covers the User endpoints.
- **Verification:** backend 47/47, Flutter 72/72, analyzer clean.

### Phase 6: Volunteer module ✅
- **Backend:**
  - Profile with computed completion.
  - Document upload: multer in memory, magic-byte type check, 5 MB cap, private Cloudinary storage behind a replaceable `DocumentStorage`, old files deleted on replace, and automatic submission for review.
  - Availability rules: approval plus a fresh location to go ACTIVE, OFFLINE clears the location, no changes while BUSY.
  - Location updates only while ACTIVE or BUSY.
  - Response workflow: list, detail, **atomic accept** (conditional updates in one transaction), decline back to the engine with exclusion, start (IN_PROGRESS), and resolve (volunteer returns to ACTIVE).
  - Reporter phone is shown only while responding, and medical information only with consent.
- **Flutter:**
  - Volunteer shell: Dashboard, Emergencies, Profile.
  - Onboarding checklist, complete-profile form, document upload (`DocumentPicker` abstraction for file_picker 13, upload progress), and verification status and result.
  - Availability switch, which sends the current location.
  - Current assignment with a 2-minute countdown, active and history lists.
  - Emergency detail: accept or decline, "I have arrived", resolve sheet with note, reporter call, consented medical info, map, directions, timeline.
  - Shared `LivePolling` mixin; the user emergency detail was refactored onto it.
  - Shared `confirmAndLogout` and `fullScreenRoute` helpers.
- **Localization:** Volunteer strings are English in V1 and fall back from hi/mr (P-19).
- **Docs:** doc 09 now covers the Volunteer endpoints.
- **Verification:** backend 69/69, Flutter 78/78, analyzer clean.

### Phase 7: Admin module ✅
- **Backend:**
  - Dashboard aggregates and a 7-day report: volumes, outcomes, average accept and resolve times, reassignment rate, per-day counts in IST.
  - Volunteer management: create with a generated one-time password and forced change, list/filter/search, documents via short-lived signed URLs, verify/reject with reviewer and note, and suspension. Suspension revokes sessions, sets the volunteer OFFLINE, and hands back any held emergency.
  - Live volunteer locations.
  - Emergency monitoring: list, detail with assignment history, reassign (engine or chosen volunteer), and resolve/cancel overrides with mandatory notes.
  - Camp CRUD with lifecycle and soft delete.
  - User listing and suspension; admins cannot suspend themselves.
- **Flutter:**
  - Admin shell: Dashboard, Emergencies, Volunteers, Camps, More.
  - Live dashboard stat cards that deep-link to filtered lists.
  - Emergency monitor and detail: reporter, responder, attempts, reassign, pick a volunteer, resolve/cancel, assignment history, timeline.
  - Volunteers: filters, search, create with a one-time password dialog, review and approve/reject, suspend, document viewer.
  - Live tracking map.
  - Camps list and form: map-tap placement, date/time pickers, active toggle, delete.
  - Users with suspend/reactivate, reports, and settings (edit account, change password, logout).
- **Refactors for reuse:**
  - Shared `showNoteSheet` replaces two near-duplicate sheets.
  - `EditAccountScreen` moved into auth, shared by User and Admin.
  - `AppFormatters.labelled` and a generic `ValueController`.
  - Temporary `RoleHomePlaceholder` deleted.
- **Bugs found by tests and fixed:**
  - Auto-disposed list controllers were invalidated after disposal; now guarded with `ref.mounted`.
  - A spinner kept animating behind the one-time password dialog.
- **Docs:** doc 09 now covers the Admin endpoints.
- **Verification:** backend 85/85, Flutter 82/82, analyzer clean.

### Phase 8: Emergency assignment engine ✅
- **Eligibility:** a `$geoNear` query on the 2dsphere index that applies every rule in doc 07. Also covers the account-suspended join, the radius, and the candidate cap.
- **Ranking:** travel time through the `RoutingService` abstraction, with OpenRouteService as the provider and a haversine fallback. The source is recorded for each assignment.
- **Atomic dispatch:**
  - A 30-second claim lock on the emergency.
  - One transaction that conditionally reserves the volunteer, creates the PENDING assignment, and moves the emergency to ASSIGNED.
  - Next candidate on a lost race. Partial unique indexes as a backstop.
- **Timeout:**
  - The 2-minute expiry warning and expiry run from a 10-second DB-driven scan, which also runs on start for restart recovery.
  - Each expiry is preserved as history and triggers an immediate reassignment that excludes that volunteer.
  - Admin escalation after 3 attempts.
- **No eligible volunteer:** the alert becomes UNASSIGNED and admins are notified (throttled). A 30-second retry job runs, plus an immediate retry when a volunteer goes ACTIVE.
- **Other hooks:**
  - Decline, going OFFLINE, and suspension hand the alert on immediately.
  - Admin manual assignment reuses the same atomic dispatch.
  - Graceful shutdown waits for in-flight engine work.
- **Tests:**
  - 28 engine tests: the 12 critical cases from doc 24, plus races (accept vs. timeout, two alerts for one volunteer), routing ranking and fallback, decline, going offline, retry, escalation, manual assignment, and restart recovery.
  - The test DB helper now waits for the engine to go idle before cleanup.
- **Docs:** doc 07 now has a "V1 implementation" section.
- **Verification:** backend 113/113 (the engine suite passed 3 repeated runs), ESLint clean.

### Phase 9: Maps, location & routing ✅
- **Backend:**
  - `GET /volunteers/me/emergencies/:id/route` (P-20) returns route geometry and ETA through the `RoutingService`. The ORS key stays server-side.
  - A straight-line fallback is used when routing is unavailable.
  - Access is limited to the holder of the active assignment.
  - Results are cached for 60 s per emergency and origin, to protect the ORS quota.
- **Flutter, tracking (D-025):**
  - Location tracking runs while ACTIVE/BUSY: an immediate report, 25 m movement updates coalesced to at most one every 10 s, and a 60 s heartbeat.
  - Android foreground service with a notification; iOS background mode.
  - Stops on OFFLINE, sign-out, or a server refusal.
  - Recovers after permission is granted or location services are turned back on.
- **Flutter, UI:**
  - Dashboard banner showing live sharing, or how to fix sharing when it is off.
  - The response map shows the road route polyline and an "N min · distance" chip. Straight-line estimates are labelled and not drawn.
  - Admin tracking map: markers coloured by state (available, responding, stale) with a legend of counts.
- **Platform:**
  - Android manifest permissions. The release build was missing `INTERNET` and now has it.
  - iOS location usage string and background mode.
- **Refactors:**
  - Volunteer test fixtures moved to `test/helpers/volunteer_fixtures.dart`.
  - `MapMarkerData.tone` added for state-coloured markers.
- **Formatting (D-024):** Dart and JS both use 100 columns. One mechanical pass across both code bases.
- **Tests:**
  - Backend: 11 new tests covering freshness, becoming eligible again after a fix, OFFLINE refusal, and the route endpoint (fallback, road geometry, cache, recompute after moving, access control, missing location, provider failure).
  - Flutter: 10 new tests covering the tracking lifecycle (coalescing, heartbeat, stop on OFFLINE, unverified/offline never tracked, permission recovery, services switched off, server refusal), the dashboard banner, the route map (road and estimate), and the admin legend and marker tones.
- **Docs:** doc 09 (route endpoint), doc 18 ("V1 implementation"), and DECISIONS D-024/D-025.
- **Verification:** backend 124/124, Flutter 92/92, ESLint and analyzer clean, formatters clean.

### Phase 10: Notifications ✅
- **Backend:**
  - Real notification service behind the interface the other services already used (24 call sites unchanged): a record per recipient, rendered in their language.
  - Templates per event and audience in en/hi/mr, with a generic fallback (D-026).
  - Payloads filtered to an allow-list of IDs; a test proves no personal or medical detail reaches a stored or pushed payload.
  - FCM through firebase-admin, sent in the background, pruning dead tokens. Without a service account it is a no-op and in-app notifications still work.
  - Endpoints: notification list, unread count, mark one/all read, device register/remove, and admin notices to volunteers.
  - Delivery failures (push or storage) never break the business flow.
- **Flutter:**
  - `PushService` interface with a Firebase implementation behind `ENABLE_PUSH` and `--dart-define` options (D-027).
  - Device registered after sign-in, removed before sign-out.
  - Notification center with a bell and unread badge on all three home screens, mark-all-read, and an empty state.
  - Deep links: a pure mapping that only produces routes inside the signed-in role's own area, and rejects malformed IDs. A tap received before the session is restored opens afterwards.
  - A foreground push refreshes the badge (no snackbar: the shell and screen scaffolds nest, so an overlay there is not reliably tappable).
  - Admin "send notice to volunteers" through the shared note sheet.
- **Tests:**
  - Backend: 20 new tests covering localization per recipient, the audience matrix, payload privacy, push fan-out and token pruning, failure isolation, device moves between accounts, read state, access control, and admin notices. Plus a template completeness test over every event.
  - Flutter: 14 new tests covering deep-link safety (per role, malformed IDs, no cross-role escape), the center and bell, device registration and removal ordering around logout, push taps (background and launch), and the foreground badge refresh.
- **Two real bugs found by the tests:** the device DELETE never ran because a subscription cancel future belongs to the root zone, and the foreground snackbar rendered behind the screen content.
- **Docs:** doc 09 (notification, device and notice endpoints), doc 19 ("V1 implementation"), and DECISIONS D-026/D-027.
- **Verification:** backend 161/161, Flutter 106/106, ESLint, Prettier and analyzer clean.

### Phase 11: Testing & security hardening ✅
- **Authorization sweep:** a matrix holding the access level of all 61 endpoints. Each is probed anonymously, with every disallowed role, suspended, and mid forced-password-change — 258 assertions. A new route that is not declared fails the test. No gaps were found.
- **Security suite (doc 24):** expired, tampered, foreign-key, wrong issuer/audience/algorithm tokens; the role inside a token ignored; deleted accounts; tokens from before a password change; operator objects rejected as credentials; unknown fields stripped instead of stored; bounded IDs, coordinates, paging and body size; malicious uploads (executable named `.pdf`, HTML named `.png`, oversized, unknown type); cross-account emergencies, assignments and notifications; admin-only volunteer locations; security headers, the CORS allowlist, rate limiting, log redaction, and error responses without internals.
- **Indexes:** a test asserting the geo, uniqueness, partial-unique (D-022) and TTL indexes exist.
- **Performance sanity:** with 120 volunteers on duty, a dispatch makes one routing call for at most `ASSIGNMENT_MAX_CANDIDATES` candidates.
- **Localization review:** a test proving every User and shared string is translated into Hindi and Marathi, with matching placeholders and no stale keys. The untranslated list is Volunteer/Admin only (P-19).
- **Small refactor:** the log redaction policy moved to `src/utils/logRedaction.js` so it can be asserted directly.
- **Findings:** no security gaps. Three tests were corrected to the implemented behavior, which is deliberate and documented: a rejected token answers `AUTH_UNAUTHORIZED` (`AUTH_INVALID` is for bad credentials), unknown request fields are stripped rather than refused, and password-change invalidation has the one-second window that JWT `iat` precision implies.
- **Docs:** doc 22 and doc 24 now have "V1 implementation" sections, including the full test inventory.
- **Verification:** backend 462/462 in 16 suites, Flutter 113/113, ESLint, Prettier and analyzer clean.

### Phase 12: Final polish & demo ✅
- **Demo data:** `npm run seed:demo` creates clearly labelled demo hospitals, camps in all three lifecycle states, four volunteers (two on duty, one off duty, one awaiting review) and a user, around Ramkund in Nashik. It is repeatable, refuses to run against production, and its logic is covered by tests (including "run twice, no duplicates").
- **`README.md`:** what the system is, an architecture and an SOS sequence diagram, repository layout, setup for backend and app, demo data, what each optional integration adds and what happens without it, the quality gates, and the pre-release caveats.
- **`DEMO.md`:** a 10-minute walkthrough — user flow, a full emergency, the reassignment and no-volunteer cases, the control room — written to be run twice in a row without resetting.
- **Diagrams:** system architecture and SOS sequence (README), backend/Flutter layering and resilience table (doc 10), and an ER diagram of every collection (doc 08).
- **Docs:** doc 13 now records the actual folder structure, and the documentation index points to the run guide.
- **Formatting:** `dart format` and Prettier across both code bases at 100 columns (D-024).
- **Verification:** backend 466/466 in 17 suites, Flutter 113/113, ESLint, Prettier and analyzer clean.

---

## Pending
Nothing: Phases 0-12 are complete, in the order given in `PROJECT_PLAN.md` §14.

## Changes after Phase 12 (owner requests, 2026-09-21)
- **First aid in the symptom checker:** `firstAidCatalog.js` adds short steps per symptom in en/hi/mr, returned as `firstAid[]` (most serious symptom first, at most 6) and shown as its own section in the result screen. Content rule kept: first-aid actions and "do not" warnings only, never a medicine name, dose or prescription — enforced by a test over every symptom. Still PENDING_CLINICAL_REVIEW.
- **Nearby facilities:** the map now stays on screen when nothing is nearby, with the explanation in a card above it, instead of replacing everything with an empty state.
- **Back gesture and exit confirmation:** `RoleShellScaffold` handles the system back gesture for every role — from any other tab it returns to the first tab, and only from there does it ask before leaving the app, so a stray swipe cannot close MedAID mid-emergency.
- **Running on a real device:** debug builds may use plain HTTP (release still requires HTTPS), and `android/gradle.properties` works around a Kotlin 2.3 compiler-daemon bug that broke `assembleDebug`. `AppConfig.devApiBaseUrl` gives debug builds a default backend address so plain `flutter run` works; `--dart-define=API_BASE_URL` still wins, and a release build without one trips an assert. README gained a troubleshooting table.
- **Emergency timeline fixes:** three separate defects made a correct history look broken. The API now sends a `reason` with each entry, so the repeated `ASSIGNING`/`UNASSIGNED` rows an emergency legitimately produces can be told apart (allow-listed, so a user's free-text cancellation reason is never shown to everyone else). The screens show seconds only when two entries share a minute — a real alert changed status three times in 0.6 s and printed the same time three times — and the date on the first row and whenever the day changes, since UTC→IST pushes an evening alert past midnight. A transition to the status an emergency already has no longer writes a history row at all, which an admin reassigning an already-ASSIGNING alert would have done. The `?? DateTime.now()` fallback that invented a timestamp for a missing one is gone. All three detail screens now share one builder.
- **The alert rings even when the app is closed or killed:** the ring is now Android's job, not the app's. The channel carries the tone as a raw resource and the alert sets `FLAG_INSISTENT`, so the OS loops it until the volunteer answers — no audio player, and nothing that needs the app alive. A background isolate (`core/notifications/background_alerts.dart`) raises the same alert from a push and answers its Accept/Decline buttons by calling the endpoints directly, reusing `AuthInterceptor` so an access token that expired while the app was closed is refreshed there too. The backend stopped sending a `notification` block for this: it made Android draw the alert on its own default channel and skip the app entirely. `audioplayers` was dropped. Channel id moved to `_v3` (Android freezes a channel's sound at creation), so phones need one reinstall.
- **Alerts keep ringing, and can be answered from the notification:** an unanswered assignment re-alerts every 15 s (alarm audio usage, ongoing, auto-cleared after 3 minutes) instead of beeping once, and the notification carries Accept and Decline buttons wired to the same endpoints as the screen. Answering silences it immediately, and a stale list refresh can no longer make it ring again for something already answered.
- **Emergency alerts on the phone:** a new assignment now raises a system notification with sound and vibration (`flutter_local_notifications`, max-importance channel), withdrawn when the assignment ends, and tapping it opens the emergency. Only while the volunteer is on duty. Android needed core library desugaring; a debug APK build confirms it compiles.
- **Hospital accuracy fix:** the sync asked Overpass for 60 results, but Overpass returns an arbitrary slice, not the nearest — near Ramkund, 9 of the 15 closest hospitals were missing while far ones were kept. It now fetches the whole area, ranks by distance and stores the closest 150, skips places mapped as closed, and falls back across Overpass mirrors. The invented demo hospitals (stored as MANUAL, so the sync protected them) are no longer seeded unless `SEED_DEMO_HOSPITALS=true`, and the four in the live database were removed. Verified: the list now starts 196 m, 344 m, 348 m, 423 m, matching OpenStreetMap exactly.
- **Real hospitals on the map:** hospitals are topped up from OpenStreetMap (Overpass) around wherever the app is used, upserted by OSM id with a 24-hour per-area cache, leaving admin-entered places alone and degrading to the stored data when Overpass is slow or down. A missing `User-Agent` made Overpass answer 406; a test now guards it. Verified live: 60 places near Ramkund.
- **App icon:** the default Flutter icon was replaced with a teal tile and a white medical cross, generated for every Android density (with an adaptive icon) and for iOS.
- **Documents open inside the app:** admins used to hand the signed Cloudinary link to a browser. `DocumentViewerScreen` now shows images in-app with pinch-zoom, and explains PDFs with an "open outside" fallback, since the app has no PDF renderer. Verified end to end against Cloudinary: PDF and image upload, and the signed URLs that serve them.
- **Verification:** backend 470/470, Flutter 116/116, ESLint, Prettier and analyzer clean.

## Known issues / notes
1. The UI reference images are still not in the repo (OQ-12). The theme follows the written design direction.
2. The Hindi and Marathi strings need review by native speakers (R-10).
3. Firebase, Cloudinary, and OpenRouteService credentials are not configured. Those features degrade gracefully until they are.
4. MongoDB is not installed locally. Development needs an Atlas URI in `backend/.env`.
