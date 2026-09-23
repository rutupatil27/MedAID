# 13 — Folder Structure

## Flutter

```text
frontend/
└── lib/
    ├── main.dart
    ├── app/
    │   ├── app.dart
    │   ├── router/
    │   └── localization/
    ├── core/
    │   ├── theme/
    │   │   └── app_theme.dart
    │   ├── constants/
    │   ├── network/
    │   ├── storage/
    │   ├── permissions/
    │   ├── utils/
    │   └── widgets/
    │       ├── buttons/
    │       ├── cards/
    │       ├── inputs/
    │       ├── loaders/
    │       ├── dialogs/
    │       ├── empty_states/
    │       └── map/
    ├── features/
    │   ├── auth/
    │   ├── user/
    │   │   ├── home/
    │   │   ├── symptoms/
    │   │   ├── facilities/
    │   │   ├── emergency/
    │   │   ├── notifications/
    │   │   └── profile/
    │   ├── volunteer/
    │   │   ├── onboarding/
    │   │   ├── verification/
    │   │   ├── dashboard/
    │   │   ├── emergencies/
    │   │   ├── location/
    │   │   └── profile/
    │   └── admin/
    │       ├── dashboard/
    │       ├── volunteers/
    │       ├── emergencies/
    │       ├── camps/
    │       ├── users/
    │       └── reports/
    └── shared/
        ├── models/
        └── enums/
```

## Backend

```text
backend/
├── src/
│   ├── config/
│   ├── routes/
│   ├── controllers/
│   ├── services/
│   │   ├── auth/
│   │   ├── emergency/
│   │   ├── assignment/
│   │   ├── volunteer/
│   │   ├── camp/
│   │   ├── symptom/
│   │   └── notification/
│   ├── models/
│   ├── repositories/
│   ├── middleware/
│   ├── validators/
│   ├── integrations/
│   │   ├── cloudinary/
│   │   ├── fcm/
│   │   └── routing/
│   ├── jobs/
│   ├── utils/
│   └── app.js
├── server.js
├── .env.example
└── package.json
```

Do not create a separate theme per role. Use one global `app_theme.dart`.

---

## V1 implementation (Phase 12)

Only additions; nothing above was moved or renamed (P-17). The differences are listed here.

### Flutter — additions to `lib/`

```text
lib/
├── core/
│   ├── files/            DocumentPicker abstraction (file_picker)
│   ├── location/         LocationService abstraction (geolocator) + providers
│   ├── notifications/    PushService abstraction (FCM) + device registration
│   └── widgets/
│       ├── chips/        StatusChip
│       ├── layout/       AppScaffold, AppHeader, SectionHeader, bottom nav + role shell
│       └── misc/         avatars, prompts, countdown, timeline, language selector
├── features/
│   ├── notifications/    the notification centre, shared by all roles (P-16, replaces
│   │                     the per-role folder in the diagram above)
│   ├── user/ volunteer/ admin/   each feature: data/ application/ presentation/(screens, widgets)
└── shared/
    ├── models/           API models shared across features
    └── enums/            role, emergency, volunteer and assignment enums
```

`core/permissions/` was not needed: permission handling lives with the capability that needs it
(`core/location`, `core/notifications`).

### Backend — additions to `backend/`

```text
backend/
├── src/
│   ├── integrations/
│   │   ├── cloudinary/   private document storage behind DocumentStorage
│   │   ├── firebase/     PushProvider (FCM), no-op when unconfigured
│   │   └── routing/      RoutingService: OpenRouteService + haversine fallback
│   └── services/
│       ├── admin/        volunteer, emergency, dashboard and report services
│       ├── facility/     hospitals and camps for users
│       └── user/         profile and account services
├── scripts/              seed-admin.js, seed-demo.js
└── tests/
    ├── helpers/          in-memory replica set, factories, scenarios
    ├── integration/      per-area API suites (doc 24)
    ├── unit/
    └── setup/
```

`src/integrations/fcm/` is named `firebase/` after the SDK it wraps.
