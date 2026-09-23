# 19 — Notification System

Use Firebase Cloud Messaging for push notifications.

## Notification events
### User
- emergency created
- volunteer assigned
- volunteer accepted
- emergency resolved
- reassignment/fallback status

### Volunteer
- new emergency assignment
- assignment expiring
- assignment cancelled
- verification approved/rejected
- important admin notice

### Admin
- new emergency
- no volunteer available
- assignment timeout/reassignment
- volunteer document submission
- verification-related event
- unresolved/escalated emergency

## Payload
Notification payload should contain IDs and event types, not unnecessary sensitive information.

Example:
{
  "type": "EMERGENCY_ASSIGNED",
  "emergencyId": "...",
  "assignmentId": "..."
}

Flutter opens the appropriate detail screen after validating authentication/authorization.

---

## V1 implementation (Phase 10)

Backend: `services/notification/` (`notification.service.js`, `templates.js`, `inbox.service.js`) and `integrations/firebase/pushProvider.js`. Flutter: `core/notifications/` (push + device registration) and `features/notifications/` (center, bell, deep links), shared by all roles (P-16).

### Interface
Business services never build notification text. They describe what happened:

```js
notificationService.notify({ type, recipients, data });  // specific accounts
notificationService.notifyAdmins({ type, data });        // every active admin
```

Delivery never breaks the business flow: failures are logged, not thrown. Pushes are sent in the background; `whenIdle()` waits for them (tests, shutdown).

### Text and language
- `templates.js` holds a title and body per event **and audience** (USER / VOLUNTEER / ADMIN), in en/hi/mr. The same event reads differently for each: `EMERGENCY_UNASSIGNED` tells the user help is still being sought, and tells admins to assign someone.
- Each record is rendered in the recipient's `preferredLanguage` when it is created, so the app shows and pushes the same text. Unknown events fall back to a generic localized message.
- Texts are deliberately generic: no names, locations or medical details, because they appear on locked screens. Hindi and Marathi need native-speaker review (R-10).

### Payload
`data` is filtered to an allow-list: `emergencyId`, `assignmentId`, `volunteerId`, `reason`. The push payload adds `type` and `notificationId`. A test asserts that no name, phone number, coordinate or medical detail ever reaches a stored or pushed payload.

### Push
- **Provider:** `sendEachForMulticast` through firebase-admin, with high priority. Tokens rejected by FCM (unregistered or invalid) are deleted.
- **Data-only, deliberately.** The message carries no `notification` block; the title and body travel inside `data`. A `notification` block tells Android to draw the alert itself, on its default channel, and to skip the app entirely when it has been killed — which would cost the emergency alert its looping ring and its Accept/Decline buttons. Data-only plus `priority: high` wakes the app's background isolate instead, so the alert is always the app's own (doc 18). iOS cannot render a data-only message, so its alert text stays in the APNs payload.
- **Not configured:** without `FCM_SERVICE_ACCOUNT_PATH` the provider is a no-op and only in-app notifications are stored, so the whole system runs without Firebase.
- **Devices:** the app registers its token after sign-in and removes it before sign-out, so a shared phone never shows the previous account's alerts. Re-registering a token moves it to the current account.
- **Flutter side:** `PushService` hides Firebase behind an interface. It is a no-op unless the app is built with `--dart-define=ENABLE_PUSH=true` plus the Firebase identifiers (`FIREBASE_API_KEY`, `FIREBASE_PROJECT_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_ANDROID_APP_ID`/`FIREBASE_IOS_APP_ID`), so no generated config files are needed (D-027).

### Notification center
- Bell with an unread badge on each role's home, opening `/notifications`.
- The list marks items read on tap and offers "Mark all read".
- The badge refreshes every 30 s and immediately when a push arrives (P-09).
- A push received while the app is in the foreground refreshes the badge; the system tray shows nothing while the app is open, and live screens poll for the change itself.

### Deep links
`notificationRoute(role, type, data)` is a pure function:
- it only produces routes inside the signed-in role's own area, so an admin payload can never navigate a user;
- IDs must be well-formed (24 hex characters), otherwise it returns null;
- events without a screen (for example an admin notice) stay in the center;
- a tap that arrives before the session is restored is opened afterwards, never before.

Authorization is still enforced twice more: the route guard for the area, and the backend for ownership (someone else's emergency returns 404).

### Admin notices
`POST /admin/notices` sends the "important admin notice" from doc 19: an admin writes up to 300 characters in the More screen, and every approved, active volunteer receives it.
