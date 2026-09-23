# 22 — Security

## Authentication
- Hash passwords using bcrypt/Argon2.
- Use signed JWTs with expiration.
- Do not store JWT secrets in source code.
- Validate login input.
- Consider refresh tokens if needed.

## Authorization
Every protected endpoint checks:
1. authenticated user
2. role
3. ownership/resource access

Examples:
- Volunteer can only accept an alert assigned to them.
- User can only view their own emergency history.
- Admin can view all emergencies/volunteers.
- Volunteer cannot verify themselves.

## Files
- Cloudinary credentials stay server-side.
- Validate uploads.
- Limit size.
- Store only required documents.
- Avoid exposing document URLs broadly.

## Location
Location is sensitive operational data. Minimize retention and exposure.

## API
- Helmet/security headers
- CORS configured explicitly
- rate limiting
- request validation
- centralized error handling
- logging without passwords/tokens

## Secrets
Use `.env` locally and environment secrets in deployment.
Provide `.env.example` with placeholders only.

---

## V1 implementation (Phase 11)

### Authentication
- bcrypt password hashing, with equalized timing so a wrong username and a wrong password take the same time.
- Access tokens: HS256, with issuer `medaid-api` and audience `medaid-app`, both verified. Tokens signed with another key, algorithm, issuer or audience are rejected.
- The role inside a token is ignored: `authenticate` reloads the account on every request, so role changes, suspensions and password changes take effect at once.
- A password change invalidates older access tokens (`passwordChangedAt` versus the token's `iat`), within the one-second precision JWT `iat` allows, and revokes every refresh token.
- Refresh tokens rotate, are stored only as SHA-256 hashes, and reuse revokes the whole family (doc 09).

### Authorization
Three checks on every protected endpoint: a valid session, the role, then ownership.

`tests/integration/authorization.test.js` holds the access level of **every** endpoint and proves each one:
- refuses anonymous callers (401),
- refuses every role that is not allowed (403),
- refuses suspended accounts (`ACCOUNT_SUSPENDED`),
- waits for a forced password change (`PASSWORD_CHANGE_REQUIRED`), except the self routes the app needs to route correctly (`/users/me`, change password).

A new route that is not listed there fails the test, so access is chosen deliberately. Ownership is enforced in the services: another user's emergency, another volunteer's assignment and another account's notifications all return 404.

### Input
- Joi validates params, query and body on every endpoint; unknown fields are stripped, so a client cannot set `role` or `accountStatus` by adding them to a profile update.
- Credentials must be strings: an operator object such as `{"$ne": null}` fails validation instead of reaching MongoDB.
- IDs must be 24-character hex, coordinates and paging are bounded, and the JSON body is capped at 100 kB.

### Files
- Type is decided by magic bytes, never by filename or the client's MIME type: an executable named `id.pdf` and HTML named `photo.png` are both rejected.
- 5 MB limit, one file per request, held in memory and never written to disk.
- Files live in Cloudinary as `authenticated` assets; admins see them through short-lived signed URLs, and storage identifiers are never returned to clients.

### Location
Volunteer positions are exposed only to admins and to the emergency being responded to. They are stored as the latest position only, cleared when a volunteer goes OFFLINE, and treated as stale after 5 minutes.

### API and logging
- helmet security headers, `x-powered-by` off, an explicit CORS allowlist (requests without an Origin, such as mobile apps, are allowed; unknown browser origins are not).
- Rate limiting: a general API limiter plus a stricter one for credential endpoints, answering `RATE_LIMITED` (429).
- Central error handling returns `{ success, message, code, errors }` with no stack traces or internal paths.
- Logging redacts authorization headers, cookies, passwords and all token fields (`src/utils/logRedaction.js`).

### Secrets
`.env` is git-ignored and `.env.example` holds placeholders only. The Cloudinary, OpenRouteService and FCM credentials stay on the backend; the Flutter app never receives them (P-20, D-027).
