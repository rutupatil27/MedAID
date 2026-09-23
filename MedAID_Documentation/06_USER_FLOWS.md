# 06 — User Flows

## User SOS
1. User taps SOS.
2. App requests/validates location permission.
3. App obtains current location.
4. User sees a minimal confirmation state if required by UX; emergency flow must not be unnecessarily slowed.
5. Backend creates alert.
6. Assignment scheduler starts.
7. Eligible volunteers are filtered.
8. Candidate volunteers are ranked.
9. Alert is dispatched.
10. Volunteer receives push notification.
11. Volunteer accepts within 2 minutes.
12. Status becomes BUSY.
13. Volunteer navigates to user.
14. Volunteer resolves alert.
15. Volunteer status becomes ACTIVE.
16. User sees final status.

## Volunteer onboarding
Admin creates account -> volunteer logs in -> completes profile -> uploads documents -> pending verification -> admin reviews -> approved -> volunteer becomes eligible to use emergency functions.

## Volunteer response
Dashboard -> assigned alert -> details/location -> accept -> BUSY -> response -> resolve -> ACTIVE.

## Camp lifecycle
Admin creates camp -> scheduled/active -> visible to Users during valid date/time -> expires/inactive automatically.
