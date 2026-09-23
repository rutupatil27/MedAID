# 12 — Backend Architecture

Node.js + Express.js.

Suggested layers:
- routes: endpoint registration
- controllers: request/response orchestration
- services: business logic
- repositories/models: MongoDB access
- middleware: auth, roles, validation, error handling
- jobs: assignment timeout/retry jobs
- integrations: Cloudinary, FCM, routing
- utils: logger, helpers
- config: environment/config loading

## Assignment worker
The assignment process may start synchronously and later move to a job queue/worker if scale requires it.

For V1, a reliable scheduler can periodically inspect pending assignments and expire those whose `expiresAt` has passed.

## Business logic
Volunteer verification, availability, assignment and emergency resolution rules must live in services, not routes.
