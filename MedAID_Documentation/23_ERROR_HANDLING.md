# 23 — Error Handling

## Flutter states
Every network-dependent screen should handle:
- loading
- success
- empty
- error
- retry

## Backend
Use centralized error middleware.

Standard codes:
- AUTH_INVALID
- AUTH_UNAUTHORIZED
- FORBIDDEN
- ACCOUNT_SUSPENDED (403) — account suspended by Admin
- PASSWORD_CHANGE_REQUIRED (403) — admin-created account must set a new password first
- RATE_LIMITED (429)
- VALIDATION_ERROR
- NOT_FOUND
- CONFLICT
- VOLUNTEER_NOT_VERIFIED
- VOLUNTEER_NOT_AVAILABLE
- EMERGENCY_ALREADY_ASSIGNED
- ASSIGNMENT_EXPIRED
- LOCATION_UNAVAILABLE
- ROUTING_UNAVAILABLE
- FILE_UPLOAD_FAILED
- INTERNAL_ERROR

## Emergency-specific failure
If routing fails:
1. Use fallback distance calculation if configured.
2. Continue assignment if safe.
3. Notify Admin when no reliable candidate can be found.

If no eligible volunteer exists:
- Keep emergency active.
- Mark as UNASSIGNED.
- Notify Admin.
- Do not falsely report that help has been assigned.
