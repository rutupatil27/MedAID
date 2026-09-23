# 07 — Emergency Assignment Engine

## Goal
Automatically assign each emergency alert to a suitable available volunteer.

## Eligibility
A volunteer is eligible only if:
- verificationStatus = APPROVED
- status = ACTIVE
- location exists and is recent enough
- volunteer account is not suspended
- volunteer is not already assigned to another active emergency

## Exclusions
- Pending verification
- Rejected
- Suspended
- Offline
- Busy
- Missing/stale location

## Assignment strategy
The engine should prefer estimated road travel time/distance when routing is available. Straight-line distance can be a fallback.

### Pipeline
SOS
-> create alert
-> lock/mark alert ASSIGNING
-> query eligible volunteers
-> obtain candidate locations
-> calculate route metrics
-> rank candidates
-> attempt atomic assignment
-> send notification
-> wait up to 2 minutes
-> accept => BUSY
-> timeout/reject => retry another candidate
-> no candidate => UNASSIGNED / admin escalation

## Dijkstra/A*
Dijkstra/A* is appropriate when a road graph is available and the system needs shortest-path calculation. A* can be more efficient when a heuristic such as geographic distance is available. For the first version, OpenRouteService can provide road-network distance/time while the assignment engine remains provider-agnostic.

## Race-condition protection
Two volunteers must not successfully claim the same alert. Acceptance must use an atomic database update such as:
- alert status is ASSIGNED
- assignedVolunteerId matches the accepting volunteer
- assignment is still active/not expired

## Timeout
Default acceptance timeout: 2 minutes.

## Reassignment
If the volunteer does not accept within 2 minutes:
1. Mark assignment EXPIRED.
2. Keep emergency alert active.
3. Exclude the expired candidate for that assignment attempt.
4. Try next eligible volunteer.
5. Notify Admin if no candidate remains.

## Volunteer state transitions
ACTIVE -> ASSIGNED/BUSY after acceptance
BUSY -> ACTIVE after successful resolution
ACTIVE -> OFFLINE when volunteer manually goes offline
OFFLINE -> ACTIVE only by volunteer action and subject to location/verification checks

## Future extension
The ranking model can later consider ETA, distance, zone, workload, signal/location freshness, and special skills without changing the alert API.

---

## V1 implementation (Phase 8)

Code: `backend/src/services/assignment/` (`eligibility.js`, `ranking.js`, `assignment.service.js`, `assignment.lifecycle.js`) and `backend/src/integrations/routing/`. Background jobs are registered in `backend/src/jobs/index.js`.

### Eligibility query
One MongoDB `$geoNear` aggregate on `volunteers.currentLocation` (2dsphere) finds the candidates. A candidate must:
- have `verificationStatus = APPROVED` and `status = ACTIVE`
- have no reservation (`currentAssignmentId` and `currentEmergencyId` both null)
- have a `currentLocation`, and a `locationUpdatedAt` no older than `LOCATION_STALE_SECONDS` (default 300)
- be within `ASSIGNMENT_SEARCH_RADIUS_METERS` (default 5000)
- have a joined user with `accountStatus = ACTIVE` and role VOLUNTEER.

The query returns at most `ASSIGNMENT_MAX_CANDIDATES` (default 10), nearest first. Volunteers already in `emergency.excludedVolunteerIds` (expired, declined, or unavailable for this alert) are skipped. They are retried only when nobody else is eligible, which is better than leaving the patient without a responder.

### Ranking
`RoutingService.matrix(origins, destination)` returns travel time and distance for each candidate. Candidates are sorted by duration, then route distance, then straight-line distance.

- **Provider:** OpenRouteService (`ORS_PROFILE`, default `foot-walking`, which suits crowded Kumbh ghats).
- **Fallback:** when there is no API key, or on a timeout or error, a haversine estimate is used. It applies a 1.3 detour factor at walking speed.
- **Recording:** the assignment stores which source was used (`distanceSource` = `ROUTING` | `FALLBACK`).

The engine never talks to ORS directly, so the provider can be swapped (see "Dijkstra/A*").

### Dispatch (atomic)
1. **Claim.** The emergency is locked for 30 s (`assignmentLockUntil`), and a CREATED alert moves to ASSIGNING. Only one worker can hold the lock.
2. **Reserve, in one transaction:**
   - The volunteer is reserved conditionally: the update matches only if they are still eligible, and it sets `currentAssignmentId` and `currentEmergencyId`.
   - A PENDING assignment is created with `expiresAt = now + ASSIGNMENT_ACCEPT_TIMEOUT_SECONDS` (default 120).
   - The emergency moves to ASSIGNED, but only while the lock still matches.
   - If any step fails, nothing is committed. The partial unique indexes (one active assignment per emergency, one per volunteer) are the last line of defence.
3. **Notify.** The volunteer gets `ASSIGNMENT_NEW` and the reporter gets `EMERGENCY_ASSIGNED`.
4. **Next candidate.** If the reservation loses a race (the volunteer went BUSY or OFFLINE in the meantime), the next ranked candidate is tried.

The volunteer stays ACTIVE (reserved) while PENDING, and becomes BUSY only on acceptance (D-008).

### No candidate
When nobody can be reserved, the alert becomes UNASSIGNED. It stays open and is never shown as assigned.

- Admins receive `EMERGENCY_UNASSIGNED` with a reason: `NO_ELIGIBLE_VOLUNTEER` or `NO_LOCATION`. An SOS without a location goes straight here.
- Admin alerts for the same emergency are throttled to one every 5 minutes.
- **Retry:** the `unassigned-retry` job (every `UNASSIGNED_RETRY_INTERVAL_MS`, default 30 s) retries waiting alerts. A retry is also triggered whenever a volunteer switches to ACTIVE.

### Timeout and reassignment
The `assignment-scan` job runs every `ASSIGNMENT_SCAN_INTERVAL_MS` (default 10 s), and once on server start so it recovers after a restart.

1. **Warning.** When an assignment has `ASSIGNMENT_EXPIRY_WARNING_SECONDS` (default 30) left, the volunteer gets `ASSIGNMENT_EXPIRING`, once only.
2. **Expiry.** Overdue assignments are handled in one transaction:
   - PENDING → EXPIRED (conditional, so an acceptance in the same instant wins or loses cleanly).
   - The emergency moves ASSIGNED → ASSIGNING, and the volunteer is added to `excludedVolunteerIds`.
   - The volunteer's reservation is released.
3. **History.** Every attempt remains in `emergency_assignments`, with `attemptNumber` and `endReason`.
4. **Notify and redispatch.** Admins get `ASSIGNMENT_EXPIRED`, and the next candidate is dispatched immediately.
5. **Escalation.** After `ASSIGNMENT_ADMIN_ALERT_AFTER_ATTEMPTS` (default 3) attempts, admins also get `EMERGENCY_ESCALATED`.

Other ways an assignment ends early:
- **Decline:** same path as expiry (`endReason = DECLINED`).
- **Volunteer goes OFFLINE or is suspended while PENDING:** the assignment ends with `VOLUNTEER_UNAVAILABLE` and the alert is redispatched at once.

### Manual assignment (Admin)
`POST /admin/emergencies/:id/reassign` with a `volunteerId` uses the same atomic dispatch and eligibility rules. An ineligible volunteer returns `VOLUNTEER_NOT_AVAILABLE`, and the alert goes back to the engine. Without a `volunteerId`, the alert is simply returned to the engine.

### Verification
`backend/tests/integration/assignment.engine.test.js` covers all 12 critical cases from doc 24, plus:
- the accept-vs-timeout race (repeated 5 times per run)
- two simultaneous SOS alerts competing for one volunteer
- ranking by road time, and the routing fallback
- decline, going offline while PENDING, and retry when a volunteer becomes ACTIVE
- the expiry warning, escalation, manual assignment, and restart recovery.
