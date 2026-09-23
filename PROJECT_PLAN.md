# MedAID — Project Plan

> **Status:** Phase 0 (Analysis & Project Plan). Draft for review.
> **Source of truth:** `MedAID_Documentation/` (see D-001 in `DECISIONS.md`).
> **Companion files:** `DEVELOPMENT_STATUS.md`, `DECISIONS.md`.
>
> This plan does not add requirements. Anything the documentation leaves open is listed in
> §15 *Documentation review* and §16 *Open questions*. Items marked **(proposed)** still need
> approval.

---

## 1. Project overview

MedAID is a mobile-first emergency health assistance platform for very large gatherings
such as Kumbh. It connects three roles:

- **User:** a person at the gathering. They can get symptom guidance, find nearby hospitals
  and temporary medical camps, and raise a one-tap SOS.
- **Volunteer:** a helper whose account is created by an Admin and then verified. Volunteers
  receive emergencies automatically, accept them, respond, and resolve them.
- **Admin:** creates and verifies volunteers, monitors emergencies and assignments, manages
  temporary medical camps, and sees basic analytics.

**Core emergency model** (from `01_PROJECT_OVERVIEW.md`):

```text
User SOS -> alert created -> eligibility filtering -> nearest/fastest eligible volunteer
 -> notification -> acceptance (≤ 2 min) -> volunteer BUSY -> assistance -> resolution
 -> volunteer ACTIVE
```

**Out of scope for V1:** QR health ID, doctor role, appointment booking, payments,
ambulance fleet management, full electronic medical records, and autonomous diagnosis. The
symptom checker gives guidance and triage support only. It does not diagnose.

---

## 2. Technology stack

| Area | Choice (from docs) | Notes |
|---|---|---|
| Mobile app | Flutter (Dart) | Installed: Flutter 3.44.0 stable, Dart 3.12.0 |
| State management | Riverpod | Mandatory; no other state library |
| Navigation | GoRouter | Role guards through `redirect` |
| Backend | Node.js + Express.js | Installed: Node 22.20.0, npm 10.9.3 |
| Database | MongoDB | Not installed locally; see OQ-06 |
| Auth | JWT + email/username + password | Passwords hashed with bcrypt/Argon2 |
| File storage | Cloudinary | Metadata only in MongoDB; secrets stay on the backend |
| Push | Firebase Cloud Messaging | Provider sits behind an interface |
| Maps | OpenStreetMap | No Google Maps dependency |
| Routing | OpenRouteService (initial) | Behind a `RoutingService` abstraction with a straight-line (haversine) fallback |
| Localization | English, Hindi, Marathi | ARB files; backend returns language-neutral error codes |
| Theme | One light global theme | `lib/core/theme/app_theme.dart` only |

Exact package versions are chosen and pinned in Phase 1 after checking compatibility with
Flutter 3.44 / Dart 3.12 and Node 22 (see §13).

---

## 3. Current working-directory assessment

| Item | Finding |
|---|---|
| Documentation | Found at **`MedAID_Documentation/`**, not `documentation/`. It has 29 files (README, manifest, 01–27). |
| Flutter project | **Exists at the repository root.** It is an untouched `flutter create` scaffold: counter-demo `lib/main.dart` and `test/widget_test.dart`, plus default `pubspec.yaml` with only `cupertino_icons`. |
| Platforms scaffolded | `android/`, `ios/`, `web/`, `linux/`, `macos/` (no `windows/`) |
| Android config | `applicationId`/`namespace` = `com.example.medaid` (placeholder); Java/Kotlin target 17 |
| Build artifacts | `build/`, `.dart_tool/`, `android/.gradle/` exist (the project has been built once) |
| Backend | **Does not exist** |
| Git | **Not a git repository**, although `.gitignore` exists |
| Local MongoDB | `mongod`/`mongosh` not found |
| UI reference images | **Not present** in the working directory (see OQ-12) |
| Other work | None. There is no custom code, theme, widgets, or backend yet. |

**Conclusion:** the project is effectively greenfield. Nothing has been deleted or modified.
The documented folder structure (`frontend/` + `backend/`) differs from the current layout,
where Flutter sits at the root. See OQ-01.

---

## 4. Architecture

### 4.1 System architecture

```text
┌──────────────────────── Flutter app (single codebase, role-based routing) ────────────────────────┐
│  User experience        Volunteer experience        Admin experience                                 │
│  presentation  →  application (Riverpod)  →  domain (entities)  →  data (repositories, API client)   │
└──────────────────────────────────────────────┬─────────────────────────────────────────────────────┘
                                               │ HTTPS REST  /api/v1  (JWT)
┌──────────────────────────────────────────────▼─────────────────────────────────────────────────────┐
│ Node.js + Express                                                                                    │
│ routes → middleware (auth, role, validation) → controllers → services → repositories → models       │
│ Services: auth · users · volunteers · verification · emergencies · ASSIGNMENT ENGINE · camps ·      │
│           facilities · symptoms · notifications · admin dashboard/reports                            │
│ Jobs:     assignment-timeout scanner · unassigned-retry                                              │
│ Integrations (interfaces): RoutingService · PushProvider · DocumentStorage                           │
└───────┬──────────────────────┬─────────────────────┬──────────────────────┬─────────────────────────┘
        │                      │                     │                      │
     MongoDB              Cloudinary       Firebase Cloud Messaging   OpenRouteService
 (2dsphere indexes)   (volunteer documents)       (push)              (road distance/ETA)
                                                                     OpenStreetMap tiles → Flutter map
```

### 4.2 Principles (from `10_SYSTEM_ARCHITECTURE.md`, `11`, `12`)

1. Business rules and authorization live in **backend services**. Hiding something in the UI
   is never enough.
2. Flutter never touches MongoDB, Cloudinary credentials, or routing API keys directly.
3. External providers (routing, push, file storage) sit behind replaceable interfaces.
4. The assignment engine is an isolated backend service. Its ranking can change without
   changing the alert API.
5. Flutter layers: **presentation → application → domain → data**, with cross-cutting
   concerns in **core**. Screens orchestrate UI only.
6. There is one global theme, one API client, and reusable widgets. Role-specific copies of
   generic components are not allowed.

### 4.3 Emergency assignment engine (summary)

**Eligibility.** All of these conditions must hold:

- `verificationStatus = APPROVED`
- operational status `ACTIVE` (not BUSY or OFFLINE)
- the account is not suspended
- the location exists and is fresher than a configurable threshold
- the volunteer has no other open emergency or pending assignment

**Pipeline:**

```text
POST /emergencies
  → emergency CREATED → ASSIGNING (atomic claim so only one worker processes it)
  → query eligible volunteers ($geoNear pre-filter, radius + limit)
  → RoutingService.matrix(candidates → emergency)   [fallback: haversine]
  → rank (ETA, then distance)
  → atomically reserve the top volunteer (conditional update) → create assignment PENDING, expiresAt = now + 2 min
  → emergency ASSIGNED → notify volunteer
  → accept (conditional update: emergency ASSIGNED ∧ assignedVolunteerId = me ∧ assignment PENDING ∧ expiresAt > now)
        → emergency ACCEPTED, assignment ACCEPTED, volunteer BUSY
  → resolve → emergency RESOLVED, assignment COMPLETED, volunteer ACTIVE
  → timeout (scheduler finds PENDING with expiresAt ≤ now, conditional update → EXPIRED)
        → release volunteer, exclude them for this emergency, retry the next candidate
  → no candidate left → emergency UNASSIGNED (still open) → notify Admin
```

Race safety uses **single-document conditional updates** (`findOneAndUpdate` with state
predicates). MongoDB transactions wrap multi-document steps where the deployment supports
them. The 12 critical test cases in `24_TESTING_STRATEGY.md` are the acceptance criteria for
Phase 8. Items still undecided (decline, IN_PROGRESS, retry policy, thresholds) are listed in
§16.

---

## 5. Roles

| Role | How the account is created | Key rules |
|---|---|---|
| **USER** | Self-registration (email/username + password) | Can see only their own emergencies. Only role that can raise SOS and use the symptom checker. Can change the app language. |
| **VOLUNTEER** | **Created by an Admin only** (no self-registration, D-016) | Must complete their profile and upload documents, then wait for Admin approval. Only APPROVED + ACTIVE volunteers get automatic assignments. Can accept or resolve only emergencies assigned to them. |
| **ADMIN** | Not self-registered. The first Admin is seeded (proposed, A-07). | Sees all volunteers, emergencies, and assignment history. Verifies volunteers, manages camps and users, can suspend accounts. |

Every protected endpoint checks, in order: **authenticated → role → ownership/resource
access** (`22_SECURITY.md`). The permission matrix comes from `05_ROLES_AND_PERMISSIONS.md`.

### State models (as documented; consolidation proposed in P-02 / OQ-07)

- **Emergency:** CREATED, ASSIGNING, ASSIGNED, ACCEPTED, IN_PROGRESS, RESOLVED, CANCELLED,
  EXPIRED, UNASSIGNED
- **Volunteer (doc 03):** PENDING_VERIFICATION, ACTIVE, BUSY, OFFLINE, SUSPENDED, REJECTED
- **Verification (doc 20):** PENDING → APPROVED | REJECTED; REJECTED → PENDING after resubmission
- **Volunteer operational transitions:** ACTIVE → BUSY (accept); BUSY → ACTIVE (resolve);
  ACTIVE ↔ OFFLINE (volunteer action, subject to checks)

---

## 6. Modules

### 6.1 Flutter feature modules

| Module | Role | Contents |
|---|---|---|
| `auth` | All | Splash, login (shared), register (User), session persistence, role redirect |
| `user/home` | User | Home dashboard, prominent SOS entry, shortcuts |
| `user/symptoms` | User | Symptom selection, triage/guidance result with safety disclaimer |
| `user/facilities` | User | Nearby hospitals + currently valid camps (list + map), facility details |
| `user/emergency` | User | SOS confirmation, active emergency status, emergency history |
| `user/profile` | User | Profile, language selection |
| `volunteer/onboarding` | Volunteer | Complete profile, document upload |
| `volunteer/verification` | Volunteer | Pending / result (approved or rejected with reason, resubmit) |
| `volunteer/dashboard` | Volunteer | Status card, Active/Offline control, current assignment |
| `volunteer/emergencies` | Volunteer | Assigned list, detail, accept, response map, resolve, history |
| `volunteer/location` | Volunteer | Location tracking lifecycle while ACTIVE/BUSY |
| `volunteer/profile` | Volunteer | Profile view/edit |
| `admin/dashboard` | Admin | KPIs, live emergency summary |
| `admin/volunteers` | Admin | List, create, detail, verification queue, document review, tracking |
| `admin/emergencies` | Admin | All alerts, detail, assignment history, reassign |
| `admin/camps` | Admin | Camp list, create/edit, activate/deactivate, map |
| `admin/users` | Admin | Users list (scope of "manage": OQ-11) |
| `admin/reports` | Admin | Basic analytics |
| `notifications` | All | Notification center (proposed shared location, P-16) |

### 6.2 Cross-cutting (core) modules

These are the theme, router and guards, localization, the network client (dio + interceptors
+ error-code mapping), secure storage, permissions, location service, push notification
service, utilities, and the shared widget library (§8).

---

## 7. Screen list (from `27_SCREEN_SPECIFICATION.md`)

Each screen must define loading, empty, and error states, its primary action, back
navigation, permissions, localization, and its API/provider dependencies. That detail is
written per phase before the screen is built.

### 7.1 User (localized en/hi/mr)

| # | Screen | Feature folder | Main provider / API |
|---|---|---|---|
| 1 | Splash | auth | authProvider (session restore) |
| 2 | Onboarding *(optional)* | auth | localeProvider |
| 3 | Login *(shared by all roles)* | auth | authProvider → `POST /auth/login` |
| 4 | Register | auth | authProvider → `POST /auth/register` |
| 5 | Home | user/home | emergencyProvider (open emergency), userProfileProvider |
| 6 | Symptom Checker | user/symptoms | symptomCheckerProvider → `GET /symptoms` |
| 7 | Symptom Result | user/symptoms | symptomCheckerProvider → `POST /symptoms/check` |
| 8 | Nearby Facilities (list + map) | user/facilities | facilitiesProvider → `GET /facilities/nearby` |
| 9 | Facility Details | user/facilities | facilitiesProvider |
| 10 | Emergency Confirmation | user/emergency | emergencyProvider → `POST /emergencies` |
| 11 | Active Emergency | user/emergency | emergencyProvider → `GET /emergencies/:id`, cancel |
| 12 | Emergency History | user/emergency | emergencyProvider → `GET /emergencies/my` |
| 13 | Notification Center | notifications | notificationProvider (endpoint missing, OQ-27) |
| 14 | Profile | user/profile | userProfileProvider → `GET/PATCH /users/me` |
| 15 | Language Selection | user/profile | localeProvider (+ `preferredLanguage`) |

### 7.2 Volunteer (English in V1, but still built on localization keys)

| # | Screen | Feature folder | Main provider / API |
|---|---|---|---|
| 1 | Login | auth (shared) | authProvider |
| 2 | Complete Profile | volunteer/onboarding | volunteerProfileProvider → `PATCH /volunteers/me` |
| 3 | Document Upload | volunteer/onboarding | volunteerProfileProvider → `POST /volunteers/me/documents` |
| 4 | Verification Pending | volunteer/verification | `GET /volunteers/me/verification` |
| 5 | Verification Result | volunteer/verification | same |
| 6 | Dashboard | volunteer/dashboard | volunteerProfileProvider, assignedEmergenciesProvider |
| 7 | Availability control *(dashboard component)* | volunteer/dashboard | volunteerAvailabilityProvider → `PATCH /volunteers/me/status` |
| 8 | Assigned Emergencies | volunteer/emergencies | assignedEmergenciesProvider → `GET /volunteers/me/emergencies` |
| 9 | Emergency Details (+ accept) | volunteer/emergencies | `GET …/:id`, `POST …/:id/accept` |
| 10 | Emergency Response Map | volunteer/emergencies | volunteerLocationProvider, route/ETA (OQ-27) |
| 11 | Resolve Emergency | volunteer/emergencies | `POST …/:id/resolve` |
| 12 | Emergency History | volunteer/emergencies | `GET /volunteers/me/emergencies?status=closed` |
| 13 | Notifications | notifications | notificationProvider |
| 14 | Profile | volunteer/profile | volunteerProfileProvider |

### 7.3 Admin (English in V1, but still built on localization keys)

| # | Screen | Feature folder | Main provider / API |
|---|---|---|---|
| 1 | Login | auth (shared) | authProvider |
| 2 | Dashboard | admin/dashboard | adminDashboardProvider → `GET /admin/dashboard` |
| 3 | Emergencies | admin/emergencies | adminEmergenciesProvider → `GET /admin/emergencies` |
| 4 | Emergency Details | admin/emergencies | `GET /admin/emergencies/:id`, reassign |
| 5 | Volunteers | admin/volunteers | adminVolunteersProvider → `GET /admin/volunteers` |
| 6 | Create Volunteer | admin/volunteers | `POST /admin/volunteers` |
| 7 | Volunteer Details | admin/volunteers | `GET /admin/volunteers/:id`, `PATCH …/status` |
| 8 | Verification Queue | admin/volunteers | `GET /admin/volunteers?verificationStatus=PENDING` |
| 9 | Document Review | admin/volunteers | `GET …/:id/documents`, verify / reject |
| 10 | Volunteer Tracking | admin/volunteers | endpoint missing (OQ-27) |
| 11 | Assignment History | admin/emergencies | `GET /admin/emergencies/:id/assignments` |
| 12 | Medical Camps | admin/camps | medicalCampsProvider → `GET /admin/medical-camps` |
| 13 | Create/Edit Camp | admin/camps | `POST` / `PATCH /admin/medical-camps` |
| 14 | Users | admin/users | endpoint missing (OQ-27) |
| 15 | Reports/Analytics | admin/reports | endpoint missing (OQ-26/27) |
| 16 | Settings | admin/… | contents undefined (OQ-26) |

---

## 8. Shared widget library (from `16_REUSABLE_WIDGETS.md`)

All widgets live under `lib/core/widgets/` and read every visual value from `app_theme.dart`.

| Group | Widgets |
|---|---|
| layout | AppScaffold, AppHeader, SectionHeader, BottomNavBar |
| buttons | PrimaryButton, SecondaryButton, EmergencyButton (DangerButton variant) |
| inputs | AppTextField, SearchField |
| chips | StatusChip |
| cards | AppCard, StatCard, FacilityCard, MedicalCampCard, EmergencyCard, VolunteerStatusCard, DocumentUploadTile |
| loaders / states | LoadingView, ErrorView (with retry), EmptyStateView |
| dialogs / feedback | ConfirmationDialog, AppSnackbar |
| map | LocationMap, MapMarker abstraction |
| misc | ProfileAvatar, PermissionPrompt, LanguageSelector |

The `layout/`, `chips/` and `misc/` subfolders extend the tree in doc 13 (P-17).

---

## 9. Backend modules

| Module | Responsibility | Service folder |
|---|---|---|
| Auth | Register (USER), login (email or username), JWT issue/verify, refresh/logout, password hashing | `services/auth` |
| Users | Own profile, preferred language; admin user listing | `services/user` *(added, P-17)* |
| Volunteers | Admin creation, profile, availability (ACTIVE/OFFLINE), location updates | `services/volunteer` |
| Verification | Document upload validation, Cloudinary storage, approve/reject with reviewer and timestamps | `services/volunteer` |
| Emergencies | SOS create (idempotent), cancel, accept, resolve, lifecycle and timestamps | `services/emergency` |
| **Assignment engine** | Eligibility, candidate search, routing metrics, ranking, atomic reservation, dispatch, timeout, reassignment, escalation | `services/assignment` |
| Camps | Admin CRUD, activation, validity window enforced in queries | `services/camp` |
| Facilities | Nearby hospitals + currently valid camps | `services/facility` *(added, P-17)* |
| Symptoms | Symptom catalogue + rule-based guidance (content source: OQ-13) | `services/symptom` |
| Notifications | Persist notifications, send push through PushProvider, device tokens | `services/notification` |
| Admin | Dashboard aggregates, reports | `services/admin` *(added, P-17)* |
| Jobs | Assignment-timeout scanner, unassigned-emergency retry | `jobs/` |
| Integrations | `routing/` (RoutingService, ORS provider, haversine fallback), `fcm/`, `cloudinary/` | `integrations/` |

Middleware includes helmet, explicit CORS, rate limiting, JSON body limits, `authenticate`,
`authorize(roles)`, `validate(schema)`, `upload` (multer, memory storage, size limit),
`notFound`, and a centralized `errorHandler` that uses the standard error envelope and codes
from `23_ERROR_HANDLING.md`.

---

## 10. Database collections

Based on `08_DATABASE_DESIGN.md`. Additions and clarifications are marked **(proposed)**.

| Collection | Key fields | Indexes |
|---|---|---|
| `users` | name, email, username, passwordHash, phone?, profile fields (OQ-16), preferredLanguage, **role ∈ USER/VOLUNTEER/ADMIN** (proposed P-03: all accounts in one collection), **accountStatus ACTIVE/SUSPENDED** (proposed P-02), mustChangePassword (proposed, OQ-09), timestamps | unique email, unique username, role |
| `volunteers` | userId (1:1), profile, **verificationStatus**, **status** (operational), currentLocation {Point, updatedAt}, **currentAssignmentId** (proposed P-04), lastActiveAt, createdBy, verifiedBy, verifiedAt, rejectionReason, timestamps | 2dsphere `currentLocation`; `{verificationStatus, status}`; unique userId |
| `volunteerDocuments` | volunteerId, documentType, cloudinaryPublicId, resourceType, deliveryType, originalName, mimeType, size, status, uploadedAt, reviewedAt, reviewedBy, reviewNote. **The public `secureUrl` is not relied on** (proposed P-12). | volunteerId |
| `emergencies` | alertNumber, userId, location {Point}, locationAccuracy, message/summary, status, assignedVolunteerId, currentAssignmentId, attemptCount, idempotencyKey (proposed P-08), createdAt, assignedAt, acceptedAt, resolvedAt, cancelledAt, resolutionNote, statusHistory[] (proposed) | status; assignedVolunteerId; userId + createdAt; unique alertNumber |
| `emergencyAssignments` | emergencyId, volunteerId, attemptNumber, routeDistance, estimatedDuration, distanceSource (ROUTING/FALLBACK), status, dispatchedAt, expiresAt, acceptedAt, rejectedAt, expiredAt, cancelledAt, completedAt | `{emergencyId, status}`; `{status, expiresAt}`; volunteerId |
| `medicalCamps` | name, description, location {Point}, address, services[], contact, startDateTime, endDateTime, isActive, createdBy, timestamps | 2dsphere `location`; `{isActive, startDateTime, endDateTime}` |
| `hospitals` | name, location {Point}, address, contact, services[], source/provider metadata, isActive (data source: OQ-18) | 2dsphere `location` |
| `notifications` | recipientUserId, type, title, body, data (IDs/event type only), readAt, createdAt | `{recipientUserId, createdAt}` |
| `refreshTokens` **(proposed, P-11)** | userId, tokenHash, expiresAt, revokedAt, replacedBy | TTL on expiresAt; userId |
| `deviceTokens` **(proposed)** | userId, fcmToken, platform, lastSeenAt | unique fcmToken; userId |
| `counters` **(proposed)** | name, seq (used for human-readable `alertNumber`) | — |
| `symptoms` **(proposed, depends on OQ-13)** | key, category, severity rules, localized guidance | key |

Raw passwords and raw files are never stored. Location history is not retained beyond the
current position unless OQ-33 decides otherwise.

---

## 11. API groups

Base path: `/api/v1`. Every response uses the standard envelope from
`09_API_SPECIFICATION.md`.

| Group | Documented endpoints | Missing endpoints needed by documented screens (**proposed**, pending OQ-27) |
|---|---|---|
| Auth | `POST /auth/login`, `/auth/register`, `/auth/refresh`, `/auth/logout` | `POST /auth/change-password` (first-login change for volunteers) |
| User | `GET/PATCH /users/me` | — |
| Symptoms | `GET /symptoms`, `POST /symptoms/check` | — |
| Facilities | `GET /facilities/nearby`, `/hospitals/nearby`, `/medical-camps/nearby` | `GET /hospitals/:id`, `GET /medical-camps/:id` (details) |
| Emergencies (User) | `POST /emergencies`, `GET /emergencies/my`, `GET /emergencies/:id`, `POST /emergencies/:id/cancel` | — |
| Volunteer | `GET/PATCH /volunteers/me`, `POST /volunteers/me/documents`, `GET /volunteers/me/verification`, `PATCH /volunteers/me/status`, `POST /volunteers/me/location`, `GET /volunteers/me/emergencies[/:id]`, `POST …/:id/accept`, `POST …/:id/resolve` | `POST …/:id/decline` (OQ-21), `POST …/:id/start` (OQ-22), `GET …/:id/route` (P-20) |
| Admin: volunteers | `POST/GET /admin/volunteers`, `GET /admin/volunteers/:id[/documents]`, `POST …/:id/verify`, `POST …/:id/reject`, `PATCH …/:id/status` | `GET /admin/volunteers/locations` (tracking), signed document view URL |
| Admin: emergencies | `GET /admin/emergencies[/:id]`, `GET …/:id/assignments`, `POST …/:id/reassign` | `POST …/:id/resolve`, `POST …/:id/cancel` (admin override, OQ-25) |
| Admin: camps | `POST/GET /admin/medical-camps`, `GET/PATCH/DELETE /admin/medical-camps/:id` | — |
| Admin: dashboard / users / reports | `GET /admin/dashboard` | `GET /admin/users`, `PATCH /admin/users/:id/status`, `GET /admin/reports/summary` (OQ-11, OQ-26) |
| Notifications | none | `GET /notifications`, `PATCH /notifications/:id/read`, `POST /notifications/read-all`, `POST /devices`, `DELETE /devices/:token` |
| Health | none | `GET /health` (ops/demo readiness) |

Following `25_AI_DEVELOPMENT_RULES.md`, `09_API_SPECIFICATION.md` is updated **before**
any new endpoint is implemented, and only after approval.

---

## 12. Folder structure (proposed)

Both trees follow `13_FOLDER_STRUCTURE.md`. Additions are marked `(+)` and explained in P-17.
The top-level placement depends on **OQ-01**. The recommended layout is:

```text
medaid/
├── MedAID_Documentation/     # source of truth (unchanged)
├── frontend/                 # Flutter app (existing root scaffold moved here, after approval)
├── backend/                  # Node.js + Express API
├── PROJECT_PLAN.md
├── DEVELOPMENT_STATUS.md
└── DECISIONS.md
```

### 12.1 Flutter (`frontend/`)

```text
frontend/
├── pubspec.yaml
├── l10n.yaml                              (+) gen-l10n config → arb-dir: lib/app/localization
├── assets/                                (+)
│   ├── fonts/                             (+) bundled fonts with Devanagari support (P-18)
│   └── images/                            (+)
├── test/                                  mirrors lib/ (widgets, providers, repositories, l10n, guards)
└── lib/
    ├── main.dart                          bootstrap: env config, Firebase init, ProviderScope, runApp
    ├── app/
    │   ├── app.dart                       MaterialApp.router: AppTheme.light, locale, delegates
    │   ├── router/
    │   │   ├── app_router.dart            GoRouter + redirect (session + role guards)
    │   │   ├── app_routes.dart            route names/paths
    │   │   └── role_shells.dart           per-role shell routes (bottom nav)
    │   └── localization/
    │       ├── app_en.arb · app_hi.arb · app_mr.arb
    │       └── locale_provider.dart       localeProvider (persisted + synced to preferredLanguage)
    ├── core/
    │   ├── theme/
    │   │   └── app_theme.dart             THE ONLY THEME SOURCE: colors, emergency tokens, typography,
    │   │                                  spacing, radii, elevations, input/button/card/chip/nav themes
    │   ├── constants/                     app_config (API base URL via --dart-define), durations, api_paths
    │   ├── network/                       api_client (dio), auth_interceptor (refresh), api_exception,
    │   │                                  api_response, error_code_mapper (code → l10n key)
    │   ├── storage/                       token_storage (secure), preferences_storage
    │   ├── permissions/                   location/notification permission helpers
    │   ├── location/                      (+) location_service (geolocator wrapper, stream lifecycle)
    │   ├── notifications/                 (+) push_service (FCM init, token, tap → route)
    │   ├── utils/                         validators, formatters, geo helpers
    │   └── widgets/
    │       ├── layout/                    (+) app_scaffold, app_header, section_header, bottom_nav_bar
    │       ├── buttons/                   primary_button, secondary_button, emergency_button
    │       ├── inputs/                    app_text_field, search_field
    │       ├── chips/                     (+) status_chip
    │       ├── cards/                     app_card, stat_card, facility_card, medical_camp_card,
    │       │                              emergency_card, volunteer_status_card, document_upload_tile
    │       ├── loaders/                   loading_view
    │       ├── empty_states/              empty_state_view, error_view
    │       ├── dialogs/                   confirmation_dialog, app_snackbar
    │       ├── map/                       location_map, map_marker
    │       └── misc/                      (+) profile_avatar, permission_prompt, language_selector
    ├── features/
    │   ├── auth/                          ┐
    │   ├── notifications/                 ┘ (+) shared by all roles (P-16)
    │   ├── user/        home/ symptoms/ facilities/ emergency/ profile/
    │   ├── volunteer/   onboarding/ verification/ dashboard/ emergencies/ location/ profile/
    │   └── admin/       dashboard/ volunteers/ emergencies/ camps/ users/ reports/
    └── shared/
        ├── models/                        user, volunteer, emergency, emergency_assignment,
        │                                  medical_camp, hospital, facility, geo_point, app_notification
        └── enums/                         user_role, volunteer_status, verification_status,
                                           emergency_status, assignment_status
```

**Inside each feature**, following `11_FLUTTER_ARCHITECTURE.md`:

```text
features/user/emergency/
├── data/            emergency_repository.dart   (calls ApiClient only; maps DTO ↔ model)
├── domain/          feature-only entities / value objects (shared entities live in shared/models)
├── application/     emergency_provider.dart      (Notifier / AsyncNotifier, exposes AsyncValue)
└── presentation/
    ├── screens/     emergency_confirmation_screen.dart, active_emergency_screen.dart, …
    └── widgets/     feature-private widgets (promoted to core/widgets once reused)
```

Use-case classes are **not** created by default. They are added only when a flow combines
several repositories ("avoid unnecessary abstractions", doc 25).

### 12.2 Backend (`backend/`)

```text
backend/
├── server.js                    load env → connect MongoDB → start HTTP → start jobs → graceful shutdown
├── package.json
├── .env.example                 placeholders only
├── scripts/                     (+) seed-admin.js, seed-demo.js (hospitals, camps, demo volunteers)
│   └── data/                    (+) seed JSON (hospitals, symptom catalogue once approved)
├── tests/                       (+)
│   ├── unit/                    services (assignment engine!), validators, utils
│   └── integration/             API + auth/role + race-condition tests (mongodb-memory-server)
└── src/
    ├── app.js                   express app: security middleware, /api/v1 router, error handler
    ├── config/                  env.js (validated), database.js, constants.js (timeouts, thresholds)
    ├── routes/                  index.js, auth, user, symptom, facility, emergency, volunteer,
    │                            admin, notification (*.routes.js)
    ├── controllers/             thin: parse request → call service → send envelope
    ├── services/
    │   ├── auth/                auth.service, token.service, password.service
    │   ├── user/                (+) user.service
    │   ├── emergency/           emergency.service (create/cancel/accept/resolve lifecycle)
    │   ├── assignment/          assignment.service (orchestrator), eligibility, ranking, dispatch
    │   ├── volunteer/           volunteer.service, availability.service, verification.service, document.service
    │   ├── camp/                camp.service
    │   ├── facility/            (+) facility.service
    │   ├── symptom/             symptom.service
    │   ├── notification/        notification.service
    │   └── admin/               (+) dashboard.service, report.service
    ├── models/                  Mongoose schemas: user, volunteer, volunteerDocument, emergency,
    │                            emergencyAssignment, medicalCamp, hospital, notification (+ proposed ones)
    ├── repositories/            one per model; the only layer that runs queries
    ├── middleware/              authenticate, authorize, validate, upload, rateLimiter, notFound, errorHandler
    ├── validators/              request schemas per route group
    ├── integrations/
    │   ├── cloudinary/          documentStorage (upload / signed URL / delete)
    │   ├── fcm/                 fcmPushProvider
    │   └── routing/             routingService (interface), openRouteServiceProvider, haversineProvider
    ├── jobs/                    scheduler, assignmentTimeout.job, unassignedRetry.job
    └── utils/                   logger, AppError, errorCodes, apiResponse, asyncHandler, geo
```

---

## 13. Dependencies

Versions are **not** pinned here. In Phase 1 each package is checked against Flutter 3.44 /
Dart 3.12 (or Node 22), and the lockfile records the result. Nothing outside the documented
stack is added without a written reason in `DECISIONS.md`.

### 13.1 Flutter packages (proposed, P-14)

| Package | Purpose | Phase |
|---|---|---|
| `flutter_riverpod` | State management (mandatory) | 1 |
| `go_router` | Navigation + role guards (mandatory) | 1 |
| `flutter_localizations`, `intl` | en/hi/mr localization, locale-aware formatting | 1 |
| `dio` | Centralized API client, interceptors (auth header, token refresh, error mapping) | 1 |
| `flutter_secure_storage` | JWT/refresh token storage | 3 |
| `shared_preferences` | Non-sensitive preferences (locale) | 1 |
| `flutter_map`, `latlong2` | OpenStreetMap rendering | 5 / 9 |
| `geolocator` | Location + permissions + Android foreground-service updates | 5 / 9 |
| `file_picker` (or `image_picker`) | Volunteer document selection | 6 |
| `url_launcher` | Call facility contact / open external navigation | 5 |
| `firebase_core`, `firebase_messaging` | FCM push | 10 |
| `flutter_local_notifications` | Show push while the app is in the foreground | 10 |
| `mocktail` (dev) | Unit/widget test mocks | 1+ |

No code generation at first (P-15): no `riverpod_generator`, `freezed`, or
`json_serializable`.

### 13.2 Backend packages (proposed, P-13)

| Package | Purpose |
|---|---|
| `express` | HTTP framework (mandatory) |
| `mongoose` | MongoDB models, 2dsphere indexes |
| `jsonwebtoken` | JWT |
| `bcryptjs` | Password hashing (no native build on Windows) |
| `joi` | Request validation |
| `helmet`, `cors`, `express-rate-limit` | Security middleware (doc 22) |
| `dotenv` | Local `.env` loading |
| `pino` (+ `pino-http`) | Structured logging with redaction of passwords/tokens |
| `multer` | Multipart document upload (memory storage, size limit) |
| `cloudinary` | Document storage SDK |
| `firebase-admin` | FCM sending |
| *(Node 22 built-in `fetch`)* | OpenRouteService HTTP calls (no axios) |
| dev: `jest`, `supertest`, `mongodb-memory-server`, `nodemon`, `eslint`, `prettier` | Testing & tooling |

### 13.3 External services and accounts

| Service | Needed by | Setup required from project owner |
|---|---|---|
| MongoDB (Atlas free tier **or** local replica set) | Phase 2 | Connection string (OQ-06) |
| Cloudinary | Phase 6 | Cloud name, API key/secret (backend `.env` only) |
| Firebase project (FCM) | Phase 10 | Final Android package name first (OQ-04); `google-services.json`; service account JSON for backend |
| OpenRouteService | Phase 8/9 | API key (backend only). Free-tier quotas apply (R-03). |
| OpenStreetMap tiles | Phase 5/9 | Attribution + tile usage policy compliance (R-04) |

### 13.4 Local toolchain (verified 2026-09-17)

Flutter 3.44.0 (stable) · Dart 3.12.0 · Node 22.20.0 · npm 10.9.3 · Git 2.50.1 · JDK 17 ·
**MongoDB: not installed**.

---

## 14. Implementation phases

This working plan uses the 13-phase sequence from the project brief. Its relationship to the
8-phase roadmap in `26_IMPLEMENTATION_ROADMAP.md` is shown in the last column (D-018).
Each phase ends with: tests passing, docs updated, `DEVELOPMENT_STATUS.md` updated, a
changed-files report, and **explicit approval before the next phase starts**.

| Phase | Scope | Exit criteria | Doc 26 |
|---|---|---|---|
| **0 Analysis & plan** | Read docs, assess workspace, plan, decisions, open questions | This file + `DEVELOPMENT_STATUS.md` + `DECISIONS.md` reviewed; blocking OQs answered | — |
| **1 Project foundation** | Apply repo layout (OQ-01); `git init` (if approved); Flutter deps; `app.dart`, `main.dart` bootstrap; Riverpod `ProviderScope`; GoRouter skeleton; gen-l10n with en/hi/mr ARB stubs; `app_theme.dart` token skeleton; dio `ApiClient`; env config via `--dart-define`; lint rules; replace counter demo and its test; backend `package.json`, tooling, `.env.example`, `.gitignore`s | `flutter analyze` clean; app boots to placeholder splash with theme + locale switching; backend lint/test scripts run | P1 |
| **2 Backend foundation** | `server.js`/`app.js`; env validation; MongoDB connection; helmet/CORS/rate limit; logger; `AppError` + error codes + envelope; `validate` middleware; `notFound`/`errorHandler`; `GET /health`; base models + indexes; test harness (Jest + Supertest + memory server) | `/api/v1/health` returns envelope; DB connected; error-envelope tests pass | P1 |
| **3 Auth & role system** | User register/login; shared login for all roles; JWT access + refresh (P-11); `authenticate`/`authorize`; account suspension check; admin seed script; Flutter auth repository/provider, secure token storage, session restore, role redirect guards; login/register/splash screens built on the first core widgets (PrimaryButton, AppTextField, LoadingView) | Auth + role + expired-token tests; guard tests; each role lands on its own shell | P2 |
| **4 Global Flutter UI system** | Complete design tokens (light healthcare aesthetic, emergency tokens); full widget library (§8) with widget tests; role shells + BottomNavBar; loading/empty/error patterns; LanguageSelector | Widget gallery/test coverage for each shared widget; no hardcoded colors/strings (lint check) | P1 |
| **5 User module** | Profile; home with prominent SOS; symptom checker (content per OQ-13); nearby facilities list + basic OSM map + details; SOS confirm → create emergency (idempotent) → active status → history → cancel; camps validity filtering on backend. **Engine not wired yet:** status shows "searching", never "assigned" | Camp expiry/filter tests; SOS idempotency tests; en/hi/mr for all User screens | P3 |
| **6 Volunteer module** | Admin-created login + first-login password flow (OQ-09); profile; document upload (backend proxy → Cloudinary, type/size/magic-byte validation); verification status; Active/Offline control with checks; location updates API; dashboard; assigned list/detail; atomic accept → BUSY; resolve → ACTIVE; history | Upload validation tests; accept/resolve ownership + state tests using seeded assignments | P4 |
| **7 Admin module** | Dashboard; create volunteer; volunteer list/detail; verification queue + document review (signed URLs) + approve/reject with reason; suspend/reactivate; emergencies list/detail + assignment history; camp CRUD + activate/deactivate + map; users list; basic reports | Admin authorization tests; verification transition tests | P5 |
| **8 Emergency assignment engine** | Eligibility query; `$geoNear` candidate search; RoutingService (ORS matrix + haversine fallback); ranking; atomic volunteer reservation + assignment; dispatch hook; 2-min timeout scanner; reassignment with exclusion; UNASSIGNED + admin escalation; manual reassign (OQ-25); restart recovery | **All 12 critical cases in doc 24 pass**, plus accept-vs-timeout, cancel-vs-accept, and double-dispatch race tests | P6 |
| **9 Maps, location & routing** | Volunteer location tracking lifecycle while ACTIVE/BUSY (foreground/background per OQ-32); stale threshold; volunteer response map with route/ETA via backend; admin volunteer tracking map; user facilities map polish | Location freshness tests; permission-denied flows; tracking stops when OFFLINE | P3/P4/P6 |
| **10 Notifications** | FCM setup (Android first); device token registration; PushProvider; event matrix from doc 19 (IDs only in payload); notification center for all roles; tap → authorized deep link; in-app polling on live screens (P-09) | Notification persistence tests; payload contains no sensitive data; deep-link guard tests | P6 |
| **11 Testing & security** | Coverage gaps; security tests from doc 24; rate limits; CORS allowlist; log redaction; upload abuse; authorization sweep of every endpoint; performance sanity check; localization review | Security test suite green; endpoint authorization matrix verified against doc 05 | P7 |
| **12 Final polish & demo** | Seed demo hospitals/camps/volunteers; full SOS → accept → resolve run on devices; reassignment demo; screenshots; architecture + ER diagrams; README/run guide; presentation material | End-to-end demo script runs cleanly twice in a row | P8 |

### 14.1 Phase ordering notes

- **Auth screens (3) come before the full UI system (4).** Phase 3 creates the few core
  widgets it needs as real reusable widgets in `core/widgets`, not throwaway ones, and Phase 4
  completes the library. The alternative is to swap Phases 3 and 4 (OQ-36).
- **User SOS (5) and Volunteer accept/resolve (6) come before the engine (8).** Those phases
  use a no-op assignment hook and seeded assignment fixtures. Until Phase 8, the UI must never
  claim that help has been assigned.
- **Basic map in 5, advanced map/location in 9.** Nearby facilities needs a map in Phase 5.
  Routing, tracking and the response map come in Phase 9.
- **Notifications (10) come after the flows that emit them.** Earlier phases call
  `NotificationService`, which only stores records until the FCM provider is connected.

### 14.2 Milestones

| Milestone | Reached at end of | Demonstrable outcome |
|---|---|---|
| **M0 Plan approved** | Phase 0 | Plan, decisions, and blocking answers agreed |
| **M1 Skeleton runs** | Phases 1–2 | App boots with theme/locale; API health check connected to MongoDB |
| **M2 Secure access** | Phase 3 | All three roles log in and land on their own guarded shells |
| **M3 Design system** | Phase 4 | Complete shared widget library, tested |
| **M4 User experience** | Phase 5 | Symptom guidance, facilities + camps, SOS created and tracked |
| **M5 Volunteer onboarding** | Phase 6 | Volunteer completes profile, uploads documents, handles a seeded emergency |
| **M6 Admin console** | Phase 7 | Admin creates/verifies volunteers, manages camps, monitors emergencies |
| **M7 Automatic dispatch** | Phase 8 | Real SOS auto-assigned; timeout → reassignment; no-volunteer escalation |
| **M8 Live location** | Phase 9 | Response map with route/ETA; admin tracking |
| **M9 Push** | Phase 10 | Every documented event pushes and deep-links correctly |
| **M10 Hardened** | Phase 11 | Security + critical test suites green |
| **M11 Demo ready** | Phase 12 | Scripted end-to-end demo, diagrams, presentation |

---

## 15. Documentation review: contradictions and gaps

| ID | Where | Finding | Handling |
|---|---|---|---|
| C-01 | Brief vs workspace | The brief refers to `documentation/`, but the folder is `MedAID_Documentation/` | Used as-is; rename only if approved (OQ-02) |
| C-02 | Doc 13 vs workspace | Docs place Flutter in `frontend/`, but the scaffold is at the repo root | OQ-01 |
| C-03 | Doc 03 vs 08/20 | Doc 03 puts verification, operational, and suspension states into one "Volunteer states" list. Docs 08/20 keep `verificationStatus` and `status` separate. | Proposed split P-02 → OQ-07 |
| C-04 | README vs 07/20; 03 vs 20 | "VERIFIED" vs "APPROVED"; "PENDING_VERIFICATION" vs "PENDING". No state is defined for a volunteer who has not yet submitted documents. | Use APPROVED/PENDING; pre-submission state name in OQ-07 |
| C-05 | Doc 07 | The transition "ACTIVE → ASSIGNED/BUSY" uses ASSIGNED, which is not a volunteer state | Volunteer stays ACTIVE but reserved while an assignment is pending (P-04) |
| C-06 | Doc 07 vs 09 + brief | Doc 07 says "timeout/**reject** → retry", and `emergencyAssignments.rejectedAt` exists, but there is no decline endpoint and the brief never mentions declining | OQ-21 |
| C-07 | Doc 03 vs 09 | "Start response" and the IN_PROGRESS state exist, but no endpoint moves an emergency to IN_PROGRESS | OQ-22 |
| C-08 | Doc 05 vs 02/20/brief | Volunteer "Register: No/self-registration" is ambiguous | Resolved by the brief: admin-created only (D-016) |
| C-09 | Doc 05 vs 09 | "Resolve: Admin override if required", but there is no admin resolve/cancel endpoint | OQ-25 |
| C-10 | Doc 08 vs 20 | `users.role = USER`, yet doc 20 creates volunteer credentials with role VOLUNTEER (and Admin needs credentials too) | One `users` collection for all roles (P-03) |
| C-11 | Doc 13 vs 19 | Notifications sit only under `features/user/`, but doc 19 defines notifications for all three roles | Shared `features/notifications` (P-16) |
| C-12 | Docs 03/27 vs 09 | Several documented screens have no endpoint: notifications (list/read/device token), admin users, reports, volunteer tracking, route/ETA, password change | OQ-27; API spec updated before implementation |
| C-13 | Doc 26 vs brief | Roadmap has 8 phases; brief has 13 with a different order | Brief governs (D-018); mapping in §14 |
| C-14 | Doc 09 | `/facilities/nearby`, `/hospitals/nearby`, and `/medical-camps/nearby` overlap | Proposed: combined list uses `/facilities/nearby`; the others serve filtered views (A-09) |
| C-15 | Doc 03 vs 07 | EXPIRED is an emergency state, but doc 07 says the emergency "remains active" when an assignment expires. When an emergency itself expires is undefined. | OQ-28 |
| C-16 | Doc 10 vs brief | "Flutter Applications" (plural) vs a single Flutter project | Single app, role-based routing (P-10), platforms in OQ-03 |
| C-17 | Doc 27 | "Login" is listed under each role | One shared login screen; the backend decides the role (P-10) |
| C-18 | Doc 08 vs 20/22 | Doc 08 stores `secureUrl`, but docs 20/22 say to "restrict document access / avoid exposing document URLs broadly" | Private/authenticated Cloudinary delivery + short-lived signed URLs (P-12) |
| C-19 | Doc 18 | Volunteer tracking "while Active + Busy" does not say whether tracking continues when the app is backgrounded or closed | OQ-32 |
| C-20 | README index | Omits `27_SCREEN_SPECIFICATION.md` (the manifest lists it) | Cosmetic; fix when docs are next updated |
| C-21 | Doc 05 | Volunteer "Nearby hospitals/camps: Optional/read-only" has no volunteer screen | Not in V1 volunteer scope unless requested (A-10) |
| C-22 | Doc 17 vs brief | Doc 17 allows Admin/Volunteer in English only; the brief requires architecture that allows localizing them later | All strings use ARB keys; hi/mr required for User + shared auth screens (P-19) |

---

## 16. Open questions

**Blocking** questions must be answered before the listed phase starts. Each includes a
recommendation, but none of them has been decided.

### 16.1 Blocking before Phase 1

| ID | Question | Why it matters | Recommendation |
|---|---|---|---|
| OQ-01 | Move the existing Flutter scaffold into `frontend/` (per doc 13), or keep Flutter at the root with `backend/` beside it? | Every path in the project depends on it | **Move to `frontend/`.** The scaffold has no custom work, so moving it is cheap, it matches the docs, and it keeps `node_modules` out of the Flutter tree. |
| OQ-02 | Rename `MedAID_Documentation/` to `documentation/`? | Paths referenced in rules and prompts | Optional. Keep the current name unless you want the brief's paths to match. |
| OQ-03 | Target platforms: Android only? iOS? Admin on Flutter Web? Keep or remove the `linux/` and `macos/` scaffolds? | FCM, background location, and maps setup differ by platform; iOS push needs an Apple developer account | **Android primary for all roles.** Admin on Android/tablet first; Flutter Web for Admin optional later. Leave the extra folders in place until you decide. |
| OQ-04 | Final application ID / bundle ID (currently `com.example.medaid`)? | Firebase app registration is tied to it; changing it later is painful | Choose now, e.g. `com.<team-or-college>.medaid` |
| OQ-05 | May I run `git init` and make an initial commit in Phase 1? | Change history and safe rollbacks | Yes, recommended |
| OQ-06 | MongoDB for development: Atlas free tier or a local install (single-node replica set)? | Transactions need a replica set; `mongod` is not installed | **MongoDB Atlas (M0).** Tests use `mongodb-memory-server` as a replica set. |

### 16.2 Needed before Phase 3 (Auth & roles)

| ID | Question | Recommendation |
|---|---|---|
| OQ-07 | Approve the volunteer state split (P-02): `verificationStatus` NOT_SUBMITTED/PENDING/APPROVED/REJECTED + operational `status` OFFLINE/ACTIVE/BUSY + account-level `accountStatus` ACTIVE/SUSPENDED? | Approve. It keeps every eligibility condition independent and testable. |
| OQ-08 | Registration fields: are both email **and** username required? Is phone required? Is email verification or password reset needed in V1? (The stack has no email service.) | Email + username + password required, phone optional. No email verification or self-service password reset in V1. |
| OQ-09 | How does a volunteer receive login details (doc 20 leaves this open)? | Admin sets a temporary password, shown once, and shares it in person. The volunteer must change it at first login (`mustChangePassword`). |
| OQ-10 | Token strategy: short-lived access JWT + rotating refresh token? Session lengths? | Yes: access ~15 min, refresh ~7 days, stored hashed and revoked on logout. A volunteer must not be logged out mid-emergency. |
| OQ-11 | What does Admin "Manage users" include: view only, suspend/reactivate, delete? | View + suspend/reactivate. No hard delete (keeps emergency history intact). |
| OQ-36 | Keep the brief's order (Auth before UI system) or swap Phases 3 and 4? | Keep the order, using the approach in §14.1 |

### 16.3 Needed before Phase 4 (UI system)

| ID | Question | Recommendation |
|---|---|---|
| OQ-12 | The "supplied UI references" are not in the workspace. Please add them (e.g. `design/references/`), plus any brand color, logo, and font preference. | Needed to build `app_theme.dart` faithfully. Without them, a neutral healthcare palette is proposed for your review first. |

### 16.4 Needed before Phase 5 (User)

| ID | Question | Recommendation |
|---|---|---|
| OQ-13 | **Symptom checker content.** Is it rule-based? Who writes and approves the symptom list, severity rules, and guidance text in en/hi/mr? Does content live in the backend (DB/JSON) or in the app? | Rule-based. Content comes from you, or from a cited public first-aid source you approve, and is stored as backend seed data with all three languages. Severity outcomes such as *Emergency → offer SOS*, *Visit nearest facility*, *General care + consult a doctor*. **I will not write medical guidance myself** (doc 25). |
| OQ-14 | SOS interaction: instant on tap, confirmation dialog, press-and-hold, or a short cancelable countdown? | Press-and-hold (~1.5 s) **or** a 3-second cancelable countdown. Both prevent accidental alerts without slowing a real one. |
| OQ-15 | If location permission is denied or there is no GPS fix, is SOS blocked or sent without location (with Admin escalation)? | Send it anyway, using the last known location if available; otherwise mark it UNASSIGNED and escalate to Admin immediately. Never silently fail. |
| OQ-16 | What does "relevant basic information" in an SOS mean? Which user profile fields exist (age, gender, blood group, allergies, conditions, emergency contact), and what consent is needed? | A minimal optional medical profile, shown only to the assigned volunteer and Admin, with a consent notice |
| OQ-17 | What does the User see about the assigned volunteer: name, phone, live location, ETA? | Name + ETA after acceptance. Phone via masked/call action if you approve. No continuous live location in V1. |
| OQ-18 | **Hospital data source and demo region.** A seeded JSON list? Imported from OSM? Which city (e.g. Nashik–Trimbakeshwar Simhastha 2027 or Prayagraj)? Should Admin manage hospitals (no screen/API exists)? | Seeded curated list for the chosen demo region. No hospital admin UI in V1. |
| OQ-19 | Which emergency states may the User cancel from, and what happens to an already-accepted volunteer? | Any non-terminal state. The pending/accepted assignment becomes CANCELLED, the volunteer is released to ACTIVE and notified. |

### 16.5 Needed before Phase 6 (Volunteer)

| ID | Question | Recommendation |
|---|---|---|
| OQ-20 | Which documents are required (ID proof, first-aid certificate, photo…)? Allowed formats and max size? Review per document or for the whole volunteer? | ID proof + a first-aid/medical credential (you confirm); PDF/JPG/PNG; ≤ 5 MB; a volunteer-level decision with optional per-document notes |
| OQ-21 | Can a volunteer **decline** an assignment (doc 07 mentions reject; API has no endpoint)? | Yes: `POST …/decline` records DECLINED and reassigns immediately, which is faster than waiting 2 minutes |
| OQ-22 | Keep the **IN_PROGRESS** state / "Start response" step (needs an endpoint) or remove it? | Keep it as an optional "Arrived / Start assistance" action. Resolve is allowed from ACCEPTED or IN_PROGRESS. |
| OQ-23 | Can an APPROVED volunteer edit profile/documents? Does that reset verification? | Contact details editable. Replacing documents sets verification back to PENDING. |
| OQ-24 | Can a BUSY volunteer go OFFLINE? What happens if an ACTIVE volunteer with a pending assignment goes OFFLINE? | BUSY → OFFLINE blocked until resolved. Going OFFLINE with a pending assignment expires it at once and triggers reassignment. |

### 16.6 Needed before Phase 7 (Admin)

| ID | Question | Recommendation |
|---|---|---|
| OQ-25 | Admin overrides: may Admin resolve or cancel an emergency? Does manual "reassign" pick a specific volunteer or re-run the engine? Must manual choices respect eligibility? | Admin may cancel/resolve with a mandatory note. Reassign either re-runs the engine or targets a volunteer who **must still pass eligibility**. |
| OQ-26 | Which report metrics are needed? What belongs on the Admin "Settings" screen? | Metrics: emergencies by status/day, average time to accept/resolve, reassignment rate, volunteer counts by status, active camps. Settings: read-only view of thresholds + admin profile/password in V1. |
| OQ-27 | Approve adding the missing endpoints listed in §11 to `09_API_SPECIFICATION.md`? | Approve in principle. Each one is documented in the phase that needs it. |

### 16.7 Needed before Phase 8–10 (Engine, maps, notifications)

| ID | Question | Recommendation |
|---|---|---|
| OQ-28 | When, if ever, does an **emergency** become EXPIRED (e.g. unresolved after N hours)? | Admin-visible escalation only. No automatic EXPIRED in V1; keep the state for admin close-out. |
| OQ-29 | Retry policy: maximum attempts? Are UNASSIGNED emergencies retried when a volunteer becomes ACTIVE? Can a volunteer whose assignment expired be tried again later? | Retry UNASSIGNED every ~30 s and whenever a volunteer goes ACTIVE. A volunteer excluded after expiry/decline is not re-tried for the same emergency unless no one else remains. No hard cap, but Admin is alerted after 3 failed attempts. |
| OQ-30 | Stale-location threshold, search radius, candidate limit? | Configurable env constants: stale after 5 min, radius 5 km, top 10 candidates by straight-line distance before routing |
| OQ-31 | Routing profile: walking or driving? (Kumbh crowd areas are largely pedestrian.) | `foot-walking` by default, configurable |
| OQ-32 | Must volunteer location keep updating when the app is backgrounded or closed? Update interval? | Android foreground service while ACTIVE/BUSY (persistent notification), updates every ~30 s or 25 m. Tracking stops when OFFLINE. |
| OQ-33 | How long is location data retained? | Store only the current location; clear it when the volunteer goes OFFLINE; no location history |
| OQ-34 | Real-time updates: FCM + periodic polling on live screens acceptable, or are WebSockets wanted? | FCM + polling (5–10 s on active-emergency and admin monitoring screens). No WebSocket dependency in V1. |
| OQ-35 | When should the "assignment expiring" warning fire? Which Admins get escalations: all admins? | Warning at 90 s. All ADMIN accounts receive escalations. |

---

## 17. Risks and technical challenges

| ID | Risk | Impact | Mitigation |
|---|---|---|---|
| R-01 | **Race conditions** among accept, timeout, user cancel, and admin reassign, plus the same volunteer being reserved by two simultaneous SOS alerts | Double assignment, stuck BUSY volunteer, false "assigned" status | Conditional single-document updates on state predicates; volunteer reservation via `currentAssignmentId: null` predicate; transactions for multi-doc steps; dedicated concurrency tests (Phase 8) |
| R-02 | **Scheduler reliability.** In-memory timers are lost on restart; multiple server instances could double-process. | Assignments never expire, or expire twice | DB-driven scanner on `expiresAt` with conditional updates (idempotent); restart recovery on boot; single backend instance assumed for V1 (P-06) |
| R-03 | **OpenRouteService quotas/outages** (free tier limits per minute/day) | Slow or failed ranking | Pre-filter candidates by `$geoNear`; one Matrix call per attempt; short timeout; haversine fallback flagged `distanceSource=FALLBACK`; assignment never blocks on routing |
| R-04 | **OSM tile usage policy.** Public tiles are not for heavy or production use. | Tiles blocked during demo or at scale | Proper attribution + app User-Agent; caching; tile URL configurable so a hosted provider can be swapped in later |
| R-05 | **Background location on Android** (foreground-service rules, background permission, OEM battery killers) | Stale locations → volunteers wrongly excluded | Foreground service while ACTIVE/BUSY; clear permission UX; stale threshold makes failure safe (excluded, never wrongly assigned); admin sees freshness |
| R-06 | **Push delivery delays** (Doze mode, OEM restrictions, no network) | Volunteer misses the 2-minute window | High-priority data messages; in-app polling on dashboard; timeout → automatic reassignment; admin escalation |
| R-07 | **Crowded mobile networks** at mass gatherings | SOS request fails or duplicates | Small payloads; retry with idempotency key; one open emergency per user; clear offline/error state with retry |
| R-08 | **GPS inaccuracy in dense crowds** | Wrong ranking or hard-to-find user | Send `locationAccuracy`; show accuracy radius on maps; volunteer can call the user if OQ-17 allows |
| R-09 | **Medical content safety/liability** | Harmful or incorrect guidance | Owner-approved content only (OQ-13); persistent "not a diagnosis" disclaimer; conservative escalation toward SOS/nearest facility |
| R-10 | **Hindi/Marathi translation quality**, especially safety text | Misunderstanding in an emergency | Native-speaker review before Phase 12; no machine-translated medical text without review |
| R-11 | **Sensitive data exposure** (locations, ID documents, health info). Indian DPDP Act considerations. | Privacy breach | Least-privilege endpoints; private Cloudinary delivery + signed URLs; no volunteer locations to Users; log redaction; minimal retention |
| R-12 | **MongoDB transactions need a replica set**; no local MongoDB installed | Blocked development/tests | Atlas for development; `mongodb-memory-server` replica set for tests (OQ-06) |
| R-13 | **Package compatibility** with the very recent Flutter 3.44 / Dart 3.12 | Build failures | Verify each package in Phase 1 before adoption; pin versions |
| R-14 | **Placeholder app ID** `com.example.medaid` | Firebase rework later | Finalize before Phase 10, ideally now (OQ-04) |
| R-15 | **Scope size** for a final-year project (3 roles, ~45 screens, real-time engine) | Schedule overrun | Strict phase gates; build the engine to its test cases; optional screens (onboarding, reports depth, settings) kept minimal |
| R-16 | **Multi-device end-to-end testing** (User + Volunteer + Admin at once) | Hard to verify real flows | Seed scripts; emulator + physical device; scripted demo run; backend integration tests cover the logic without devices |
| R-17 | **Document upload abuse** (spoofed extensions, oversized files) | Security issue, storage cost | Magic-byte check, MIME allowlist, size cap in multer, per-user rate limit, Cloudinary private delivery |

---

## 18. Assumptions

Each assumption is marked **(to confirm)**. None of them is treated as a decision until you
confirm it. Most match a recommendation in §16.

| ID | Assumption |
|---|---|
| A-01 | Mobile-first: Android is the primary target for all three roles (to confirm, OQ-03). |
| A-02 | One Flutter app serves all roles through role-based routing after a shared login (to confirm, P-10). |
| A-03 | The backend runs as a single instance for V1/demo (to confirm, P-06). |
| A-04 | The acceptance timeout (2 min), stale-location threshold, search radius, and candidate limit are backend config constants, and the timeout defaults to exactly 2 minutes (to confirm, OQ-30). |
| A-05 | Symptom-checker content will be provided or approved by the project owner. I will not author clinical guidance (to confirm, OQ-13). |
| A-06 | Admin and Volunteer screens ship in English in V1 but use localization keys throughout (P-19). |
| A-07 | The first Admin account is created by a backend seed script using credentials from `.env` (to confirm). |
| A-08 | A user may have at most one open (non-terminal) emergency at a time. A repeated SOS returns the existing open emergency (to confirm, P-08). |
| A-09 | `/facilities/nearby` returns hospitals + currently valid camps together. `/hospitals/nearby` and `/medical-camps/nearby` serve filtered views (to confirm). |
| A-10 | Volunteers do not get a nearby-facilities screen in V1 (to confirm). |
| A-11 | Hospitals are demo seed data for one chosen region. There is no hospital management UI in V1 (to confirm, OQ-18). |
| A-12 | Dark mode is out of scope (README states a light theme). |
| A-13 | Deleting a camp is a soft delete/deactivation so historical references remain valid (to confirm). |

