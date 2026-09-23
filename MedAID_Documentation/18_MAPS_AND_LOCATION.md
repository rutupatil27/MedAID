# 18 — Maps & Location

## Map provider
Use OpenStreetMap-based map rendering.

## Routing
Use OpenRouteService initially for road distance/ETA. Keep routing behind a `RoutingService` abstraction.

## User map
Display:
- current user location
- hospitals
- currently valid temporary medical camps
- selected facility details

## Volunteer map
Display:
- user emergency location
- volunteer current location
- route/ETA where available

## Location tracking
Volunteer location is tracked while Active + Busy according to permissions and battery-aware intervals.

## Freshness
Store `updatedAt` with volunteer location. Assignment should reject stale location data according to a configurable threshold.

## Temporary camp filtering
A camp is visible to Users when:
- isActive = true
- current time is within startDateTime and endDateTime

## Privacy
Only expose a volunteer's location to Admin and the emergency response workflow as required. Do not expose all volunteer locations to ordinary Users.

---

## V1 implementation (Phase 9)

### Rendering
`core/widgets/map/LocationMap` wraps flutter_map with OpenStreetMap tiles and the required attribution. Screens pass provider-independent `MapMarkerData`, plus an optional route polyline. No screen talks to flutter_map directly.

### Volunteer location tracking (OQ-32)
Code: `features/volunteer/application/location_tracking_controller.dart`, kept alive by `LocationTrackingScope` around the volunteer shell.

- **When it runs:** tracking starts automatically while the volunteer is APPROVED and ACTIVE or BUSY. It stops immediately when they go OFFLINE, when the server refuses an update with `VOLUNTEER_NOT_AVAILABLE` (e.g. after a suspension), or when they sign out.
- **Updates:**
  - an immediate report on start
  - movement updates at a 25 m distance filter (Android request interval 30 s), coalesced to at most one every 10 s
  - a 60 s heartbeat with a fresh fix when nothing was sent, so a stationary volunteer never exceeds `LOCATION_STALE_SECONDS` (300 s).
- **Background:**
  - Android runs a foreground service with a persistent notification (`FOREGROUND_SERVICE_LOCATION`).
  - iOS uses `UIBackgroundModes=location` with the system's background indicator.
  - Background location permission (`ACCESS_BACKGROUND_LOCATION` / "Always") is **not** requested, because the service starts while the app is in the foreground.
  - If the app is closed, tracking stops. The stored location then goes stale and the engine stops dispatching to that volunteer, which is the safe outcome.
- **Permission denied or services off:** the dashboard shows "Location sharing is off" with Allow or Open settings. Tracking resumes on its own once access is restored (it is rechecked every heartbeat).
- **Endpoint:** updates use `POST /volunteers/me/location`, which is accepted only while ACTIVE or BUSY.

### Freshness
- The backend stores `locationUpdatedAt` and marks views with `isStale` (older than `LOCATION_STALE_SECONDS`, default 300 s).
- The assignment engine ignores stale volunteers (doc 07). A new fix makes them eligible again, and the `unassigned-retry` job offers them waiting alerts within 30 s.

### Volunteer response map
- **Markers:** the emergency location, and my location (the latest tracked fix).
- **Route and ETA:** from `GET /volunteers/me/emergencies/:id/route` (P-20: the ORS key never ships in the app).
  - Fetched only while I hold the active assignment, and refreshed every 60 s. The backend also caches the result.
  - A road route is drawn as a polyline, with an "N min · distance" chip.
  - A straight-line estimate (`FALLBACK`) is labelled as an estimate and **not** drawn as a path.
- **Directions:** the button hands off to the device's maps app (a `geo:` intent, falling back to OSM directions).

### Admin tracking map
- **Data:** `GET /admin/volunteers/locations`, polled every 10 s. It covers ACTIVE and BUSY volunteers with a stored location.
- **Marker colours:** by state: available (ACTIVE), responding (BUSY), or greyed out when the location is stale.
- **Legend:** a count per state. Tapping a marker opens the volunteer's details.

### Hospitals from OpenStreetMap
Camps are entered by admins, but hospitals come mostly from OpenStreetMap, so the map is useful
anywhere rather than only where someone has typed places in.

- **Source:** the Overpass API, asked for `amenity=hospital|clinic` around the point being viewed.
- **Never a capped slice:** Overpass cannot sort, and `out ... N` returns an arbitrary N — which hid
  hospitals a few hundred metres away behind others kilometres out. The sync asks for everything in
  the area (the same cost), ranks by distance here, and keeps the closest `OSM_MAX_RESULTS` (150).
- **Closed places are dropped:** anything tagged `disused:`, `abandoned:`, `was:` or
  `operational_status=closed` is never offered as somewhere to go.
- **Mirrors:** `OSM_OVERPASS_URL` is a comma-separated list, tried in order, because public
  instances frequently answer 504 or 429.
- **Stored, not proxied:** results are upserted into `hospitals` with `source.provider = OSM` and the
  OSM id, so repeated syncs update rather than duplicate, and the normal `$geoNear` query serves them.
  Hospitals added by an admin or a seed carry a different source and are never touched.
- **Politeness:** each area (~1 km cell) is fetched at most once per `OSM_CACHE_HOURS` (default 24),
  parallel requests for the same area share one call, and the request identifies itself with a
  `User-Agent` as the OSM usage policy requires (Overpass answers 406 without one).
- **Never blocks the person:** the first look at an empty area waits for the sync so the map is not
  empty; after that refreshes happen in the background. A timeout or an Overpass outage just means
  the map shows what the database already holds.
- **Off switch:** `OSM_HOSPITAL_SYNC=false`.

### User map
- Shows the user's location, nearby hospitals, and currently valid camps (validity is filtered by the backend, doc 21).
- Tapping a marker opens the facility details screen.
- Missing permission or disabled location services show `LocationAccessPrompt`.

### Emergency alerts on the volunteer's phone
A dispatched volunteer has two minutes to answer, so the app raises a **system notification** with
sound and vibration as soon as an assignment appears (`core/notifications/local_notifier.dart`,
Android channel `medaid_emergency_alerts_v3` at max importance).

- Raised by the app itself, so it needs no Firebase and also covers what push cannot: an app that
  is already open.
- **It keeps ringing, and Android does the ringing.** A notification sound is one short chime, so
  the alert carries `FLAG_INSISTENT`: the OS repeats the channel's tone until the notification goes
  away. It is marked ongoing, so it cannot be swiped away while it still needs an answer, and
  Android clears it by itself after three minutes should the app die first. The app additionally
  re-raises the banner every `AppConfig.alertRepeatInterval` (15 s) so it stays in front of the
  volunteer.

  The tone lives at `android/app/src/main/res/raw/emergency_ring.wav` — an Android resource rather
  than a Flutter asset, because the OS has to play it when no Dart code of ours exists to.
- **Answering does not need the app.** The alert carries **Accept** and **Decline** buttons, which
  call the same endpoints as the screen does; accepting then opens the emergency. An emergency
  answered this way stops ringing at once, even before the list refresh confirms it.
- **It rings when the app is closed, or killed.** `core/notifications/background_alerts.dart` runs
  in a background isolate that Android spawns for a push: it raises the same alert, on the same
  channel, with the same buttons. Pressing Accept or Decline there calls the endpoint straight from
  the isolate — rebuilding the app's `AuthInterceptor` by hand, so an access token that expired
  while the app was closed is refreshed exactly as it would be in the app. This is why the backend
  sends **data-only** pushes (doc 19): a `notification` block would have Android draw the alert on
  its own default channel and never wake the app at all.
- **Channel ids carry a version.** Android freezes a notification channel's sound and importance
  when it is first created and ignores later code changes, so a phone that had an older build kept
  the old, quieter channel. Changing how the alert sounds therefore means a new channel id
  (`_v3` at the time of writing), and the retired ids are deleted on start so they do not linger in
  the phone's settings. **Volunteers must reinstall or re-run the app after such a change.**
- **What can still silence it:** Do Not Disturb unless alarms are allowed through, and the
  aggressive battery managers on some Android skins (Xiaomi, Oppo, Vivo, Realme), which block
  background wake-ups until the app is allowed to autostart. Both affect every app that does this,
  including ordinary calling apps.
- One alert per assignment; it is withdrawn as soon as the assignment is accepted, declined or
  expires.
- Tapping the alert itself (not a button) opens that emergency; declining is also available on the
  emergency screen.
- Only while the volunteer is APPROVED and ACTIVE or BUSY — nobody off duty is interrupted.

### Platform configuration
- **Android** (`AndroidManifest.xml`): `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, `WAKE_LOCK`, `POST_NOTIFICATIONS`. geolocator declares the foreground service itself.
- **iOS** (`Info.plist`): `NSLocationWhenInUseUsageDescription` and `UIBackgroundModes: location`.
