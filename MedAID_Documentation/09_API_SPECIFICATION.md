# 09 — API Specification

Base:
`/api/v1`

## Auth
POST `/auth/login` — body `{ identifier (email or username), password }`
POST `/auth/register` — body `{ name, email, username, password, phone?, preferredLanguage? }`; always creates role USER
POST `/auth/refresh` — body `{ refreshToken }`; rotates the refresh token (reuse of a rotated token revokes the session family; 20 s grace for lost responses)
POST `/auth/logout` — body `{ refreshToken? }`; revokes the session family
POST `/auth/change-password` — auth required; body `{ currentPassword, newPassword }`; clears `mustChangePassword`, ends all other sessions

Session response (`data`) for login/register/refresh/change-password:
`{ user, accessToken, refreshToken, accessTokenExpiresAt }`

Access tokens are short-lived JWTs (default 15 min). Accounts with `mustChangePassword = true` receive `PASSWORD_CHANGE_REQUIRED` from role-protected endpoints until they change their password. Suspended accounts receive `ACCOUNT_SUSPENDED` immediately.

## System
GET `/health` — `{ status, database, uptimeSeconds, time }`

## User
GET `/users/me` — any role
PATCH `/users/me` — `{ name?, phone?, preferredLanguage?, medicalProfile? }` (medicalProfile: USER only; includes `shareWithResponders` consent)

GET `/symptoms` — USER; localized via `Accept-Language` (en/hi/mr); `{ contentStatus, categories[{ key, name, symptoms[{ key, name }] }] }`
POST `/symptoms/check` — USER; `{ symptoms[], ageGroup?, pregnant?, durationDays? }` → `{ level: EMERGENCY|URGENT|ROUTINE, title, message, firstAid[], advice[], actions[SOS|CALL_EMERGENCY|FIND_FACILITY], warningSigns[], redFlags[], selectedSymptoms[], disclaimer, contentStatus }`. Content status is `PENDING_CLINICAL_REVIEW` until reviewed.
`firstAid[]` holds short steps for the symptoms that were selected (most serious first, at most 6), localized like the rest. It contains first-aid actions and "do not" warnings only — never a medicine name, a dose or a prescription, which a test enforces.

GET `/facilities/nearby?latitude&longitude&radiusMeters?&limit?&type=ALL|HOSPITAL|CAMP` — hospitals + camps valid right now, nearest first, with `distanceMeters`. Hospitals are topped up from OpenStreetMap for the area being looked at (doc 18), so the map is not limited to hand-entered places.
GET `/hospitals/nearby`, GET `/medical-camps/nearby` — single-type variants
GET `/hospitals/:id`, GET `/medical-camps/:id` — details (a camp outside its validity window returns 404)

POST `/emergencies` — USER; body `{ latitude?, longitude?, accuracy?, message? }` (coordinates optional: SOS without a GPS fix is allowed and escalated). Optional header `Idempotency-Key`. Returns 201 when created, 200 with the existing emergency when the key was already used or the user already has an open emergency (one open emergency per user).
GET `/emergencies/my?page&limit&open` — paged `{ items, page, limit, total }`
GET `/emergencies/:id` — owner only (others get 404); includes `timeline[]` and `responder { name, estimatedDurationSeconds, routeDistanceMeters }` once a volunteer has accepted

Each `timeline[]` entry is `{ status, at, reason }`. `reason` explains *why* the status changed
(`NO_ELIGIBLE_VOLUNTEER`, `CANDIDATES_UNAVAILABLE`, `VOLUNTEER_UNAVAILABLE`, `NO_LOCATION`,
`TIMEOUT`, `DECLINED`, `ADMIN_REASSIGNED`) and is `null` otherwise. The engine retries, so a
timeline legitimately repeats `ASSIGNING` and `UNASSIGNED`; the reason is what tells the repeats
apart. It is an allow-list: the stored `note` also holds free text — a user's cancellation reason,
an admin's closing note — which is never echoed into anyone else's timeline.
POST `/emergencies/:id/cancel` — `{ reason? }`; allowed while open; frees any reserved/BUSY volunteer; 409 if already closed

## Volunteer
All require role VOLUNTEER.

GET `/volunteers/me` — `{ id, user, profile, profileCompleted, verificationStatus, submittedAt, verifiedAt, rejectionReason, status, location{latitude, longitude, accuracy, updatedAt, isStale}, currentEmergencyId, requiredDocuments[], documents[] }`
PATCH `/volunteers/me` — profile fields `{ phone, dateOfBirth, gender, address, city, languages[], skills[], emergencyContactName, emergencyContactPhone }`; `profileCompleted` is computed (phone, address, city and emergency contact are required)
POST `/volunteers/me/documents` — multipart `file` + `documentType` (ID_PROOF | FIRST_AID_CERTIFICATE | OTHER). PDF/JPEG/PNG detected by content, ≤ 5 MB (413 otherwise). Replacing a document keeps one current copy and deletes the old file. When all required documents are on file the volunteer moves to PENDING review; replacing a required document after approval also returns them to PENDING (and OFFLINE). Returns `{ document, verificationStatus }`. Storage references are never returned.
GET `/volunteers/me/verification`
PATCH `/volunteers/me/status` — `{ status: ACTIVE|OFFLINE, latitude?, longitude?, accuracy? }`. ACTIVE requires APPROVED verification (`VOLUNTEER_NOT_VERIFIED`) and a fresh location, either in the body or already stored (`LOCATION_UNAVAILABLE`). BUSY volunteers cannot change availability (`VOLUNTEER_NOT_AVAILABLE`). OFFLINE clears the stored location.
POST `/volunteers/me/location` — `{ latitude, longitude, accuracy? }`; accepted only while ACTIVE or BUSY
GET `/volunteers/me/emergencies?scope=ACTIVE|HISTORY&page&limit` — emergencies dispatched to me, each with `assignment` and `reporter`
GET `/volunteers/me/emergencies/:id` — 404 unless I was dispatched to it. The reporter's phone is shown only while I am responding, and their medical profile only with their consent.
GET `/volunteers/me/emergencies/:id/route` — route and ETA from my stored location to the emergency: `{ origin, destination, distanceMeters, durationSeconds, source: ROUTING|FALLBACK, geometry[{latitude, longitude}], originUpdatedAt, computedAt }`. Only for the volunteer holding the active (PENDING/ACCEPTED) assignment, otherwise 404. Returns `LOCATION_UNAVAILABLE` (422) when the emergency or I have no location. The routing key stays on the backend (P-20). When routing is unavailable it returns a straight-line estimate (`FALLBACK`, geometry = the two end points), so it never fails for routing reasons. Results are cached for 60 s per emergency and origin (≈11 m).
POST `/volunteers/me/emergencies/:id/accept` — atomic; `ASSIGNMENT_EXPIRED` (410) after 2 minutes, `EMERGENCY_ALREADY_ASSIGNED` (409) if no longer awaiting me; repeating it is idempotent. Volunteer becomes BUSY.
POST `/volunteers/me/emergencies/:id/decline` — `{ reason? }`; the emergency returns to the engine with me excluded
POST `/volunteers/me/emergencies/:id/start` — ACCEPTED → IN_PROGRESS ("I have arrived")
POST `/volunteers/me/emergencies/:id/resolve` — `{ resolutionNote }` (required); → RESOLVED, assignment COMPLETED, volunteer BUSY → ACTIVE

## Admin
All require role ADMIN.

GET `/admin/dashboard` — `{ emergencies{open, unassigned, awaitingAcceptance, inProgress, today, openByStatus}, volunteers{byVerification, byStatus, pendingVerification}, users{USER, VOLUNTEER, ADMIN}, camps{activeNow}, recentOpenEmergencies[] }`
GET `/admin/reports/summary?from&to` — defaults to the last 7 days; `{ range, emergencies{total, resolved, cancelled, open, reassigned, everUnassigned, reassignmentRate, avgTimeToAcceptSeconds, avgTimeToResolveSeconds}, perDay[{date, count}] }`

POST `/admin/volunteers` — `{ name, email, username, phone?, temporaryPassword? }` → `{ volunteer, temporaryPassword }`. The password is generated when not given, returned once, and must be changed at first login.
GET `/admin/volunteers?verificationStatus&status&accountStatus&search&page&limit`
GET `/admin/volunteers/locations` — ACTIVE/BUSY volunteers with `location{latitude, longitude, updatedAt, isStale}` (admin only)
GET `/admin/volunteers/:id`
GET `/admin/volunteers/:id/documents` — documents with short-lived signed `url` (storage identifiers never returned)
POST `/admin/volunteers/:id/verify` — `{ note? }`; PENDING → APPROVED (409 otherwise); pending documents → APPROVED; records verifiedBy/verifiedAt
POST `/admin/volunteers/:id/reject` — `{ reason }` (required); PENDING → REJECTED; pending documents → REJECTED with the note
PATCH `/admin/volunteers/:id/status` — `{ accountStatus: ACTIVE|SUSPENDED }`. Suspension signs the volunteer out everywhere, sets them OFFLINE, and returns any emergency they hold to the engine.

GET `/admin/emergencies?status&open&search&page&limit` — includes `reporter`, `assignedVolunteer{id, name, phone, status}` and `attemptCount`
GET `/admin/emergencies/:id` — also `assignments[]` (with volunteer) and the reporter's consented medical profile
GET `/admin/emergencies/:id/assignments`
POST `/admin/emergencies/:id/reassign` — `{ volunteerId? }`. Releases the current volunteer (excluded from this emergency), then re-runs the engine or assigns to the given volunteer, who must still pass every eligibility rule.
POST `/admin/emergencies/:id/resolve` — `{ note }` (required); admin override
POST `/admin/emergencies/:id/cancel` — `{ note }` (required); admin override

POST `/admin/medical-camps` — `{ name, description?, latitude, longitude, address, services[], contact{name, phone}, startDateTime, endDateTime (> start), isActive? }`
GET `/admin/medical-camps?status=ALL|ACTIVE_NOW|UPCOMING|EXPIRED|INACTIVE&search&page&limit` — each with `lifecycle`
GET `/admin/medical-camps/:id`
PATCH `/admin/medical-camps/:id` — any subset of fields (validity window re-checked)
DELETE `/admin/medical-camps/:id` — soft delete (deactivated, hidden from users, kept for history)

GET `/admin/users?role&accountStatus&search&page&limit`
PATCH `/admin/users/:id/status` — `{ accountStatus }`. Volunteer accounts use the volunteer suspension flow; admins cannot change their own status.

POST `/admin/notices` — `{ message }` (3–300 characters); sends an ADMIN_NOTICE to every APPROVED volunteer with an active account. Returns `{ recipients }`. The admin's text becomes the notification body; the title is localized.

## Notifications
Every signed-in role, scoped to "me".

GET `/notifications?page&limit&unreadOnly` — `{ items[{ id, type, title, body, data, isRead, readAt, createdAt }], page, limit, total, unreadCount }`, newest first. `title`/`body` are already localized to the account's `preferredLanguage`; `data` holds IDs only (doc 19).
GET `/notifications/unread-count` — `{ unreadCount }` (badge polling, P-09)
PATCH `/notifications/:id/read` — marks one read; another account's notification returns 404. Repeating it keeps the first `readAt`.
POST `/notifications/read-all` — `{ updated }`

POST `/devices` — `{ token, platform: android|ios|web }`; registers this device for push. A token belongs to one device, so registering it again moves it to the current account.
DELETE `/devices/:token` — removes the token for the signed-in account (`{ removed }`); the app calls it before signing out.

## Standard response
Success:
{
  "success": true,
  "message": "...",
  "data": {}
}

Error:
{
  "success": false,
  "message": "...",
  "code": "ERROR_CODE",
  "errors": []
}

## Rules
- Validate every request.
- Return appropriate HTTP status codes.
- Never return passwordHash.
- Never expose Cloudinary secrets.
- Keep DTO/response shape stable.
