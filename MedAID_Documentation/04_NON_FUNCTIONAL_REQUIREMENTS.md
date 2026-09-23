# 04 — Non-Functional Requirements

## Performance
- Normal API responses should target low-latency responses under expected project/demo load.
- Emergency assignment should begin immediately after alert creation.
- UI must remain responsive during API calls.

## Reliability
- Alert creation must be idempotent where practical to reduce duplicate SOS alerts.
- Assignment must be transactional/guarded against two volunteers accepting the same alert.
- All critical status changes should be timestamped.

## Security
- Passwords must be hashed using a strong password hashing algorithm.
- JWT secrets must never be hardcoded.
- Sensitive configuration belongs in environment variables.
- Role authorization must be checked server-side.
- Volunteer documents must not be publicly exposed by MongoDB.

## Usability
- Emergency controls must be obvious.
- Loading, empty, success, and error states are required.
- Language switching must not require reinstalling the app.
- Forms should provide clear validation.

## Maintainability
- Feature-first/role-aware structure.
- Reusable widgets.
- Centralized theme.
- Centralized API client.
- Repository/service separation.
- Consistent naming.

## Scalability
- Assignment engine should be isolated behind a service interface.
- Routing provider must be replaceable.
- Notification provider must be replaceable.
