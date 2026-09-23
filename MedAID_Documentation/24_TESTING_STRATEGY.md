# 24 — Testing Strategy

## Flutter
- widget tests for reusable widgets
- unit tests for providers/controllers
- repository/API parsing tests
- localization tests
- navigation/role guard tests

## Backend
- unit tests for services
- API integration tests
- authentication/authorization tests
- assignment engine tests
- document upload validation tests
- camp expiry/filtering tests

## Critical assignment test cases
1. One active verified volunteer -> assigned.
2. Busy nearest volunteer -> skipped.
3. Offline nearest volunteer -> skipped.
4. Unverified volunteer -> skipped.
5. Missing location -> skipped.
6. Stale location -> skipped.
7. Volunteer accepts within 2 minutes -> BUSY.
8. No acceptance for 2 minutes -> reassignment.
9. Two volunteers attempt acceptance simultaneously -> only one succeeds.
10. Resolution -> volunteer ACTIVE.
11. No eligible volunteer -> Admin notified.
12. Volunteer goes Offline -> cannot receive new automatic assignment.

## Security tests
- unauthorized role access
- expired JWT
- invalid input
- malicious upload
- access to another user's emergency
- volunteer attempting another volunteer's assignment

---

## V1 test suites (Phase 11)

Run with `npm test` (backend) and `flutter test` (app). Both must be green, together with ESLint, Prettier and `flutter analyze`.

### Backend — `backend/tests`
| Suite | Covers |
|---|---|
| `foundation` | app boot, health, error envelope, validation middleware |
| `auth` | register, login, refresh rotation and reuse revocation, logout, change password |
| `symptoms` | rule-based guidance, language, conservative escalation |
| `facilities` | nearby ordering, camp validity window, details |
| `emergencies.user` | SOS idempotency, one open alert, history, owner-only access, cancellation |
| `volunteers.self` | profile, documents, availability rules, location |
| `volunteers.response` | list, detail, atomic accept, decline, start, resolve |
| `volunteers.location` | location freshness, stale recovery, route/ETA endpoint |
| `assignment.engine` | doc 07 rules and the 12 critical cases below, plus races and bounded work |
| `admin` | volunteers, verification, emergencies, camps, users, reports, suspension |
| `notifications` | persistence per recipient language, payload privacy, push fan-out, devices, read state, admin notices |
| `authorization` | the access level of every endpoint (see doc 22) |
| `security` | tokens, injection attempts, malicious uploads, cross-account access, CORS, rate limiting, log redaction |
| `indexes` | geo, uniqueness and TTL indexes the system depends on |
| `unit/authorize`, `unit/notificationTemplates` | role gate, template coverage in all three languages |

### Flutter — `frontend/test`
| Suite | Covers |
|---|---|
| `app/route_guard`, `app/app_boot` | role redirects, session restore |
| `app/localization` | User and shared strings translated into hi/mr, placeholder parity |
| `architecture/design_rules` | one theme file, no hardcoded colours, no literal UI strings, no API calls in widgets |
| `core/network`, `core/widgets` | envelope and error mapping, refresh single-flight, shared widgets |
| `features/auth` | login, register, forced password change, logout |
| `features/user` | SOS hold and retry, emergency status, symptoms, facilities, profile |
| `features/volunteer` | onboarding, documents, availability, response actions, location tracking, response route |
| `features/admin` | dashboard, volunteers, verification, camps, tracking map |
| `features/notifications` | deep-link safety, center and bell, push registration and taps |

### Critical assignment cases
All twelve cases listed above are covered in `assignment.engine`, together with: accept versus timeout races, two alerts competing for one volunteer, routing failure fallback, ranking by travel time, decline, going offline while holding an assignment, retry when a volunteer becomes available, escalation, manual assignment, and restart recovery.
