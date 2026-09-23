# 25 — AI Development Rules

This file is mandatory context for AI coding tools working on MedAID.

## Before coding
1. Read README.md and the relevant documentation.
2. Inspect the existing project structure.
3. Search for reusable widgets/services/providers before creating new ones.
4. Identify whether the requested change affects frontend, backend, API contracts, database, or multiple layers.

## Architecture rules
- Flutter + Riverpod only for state management.
- Node.js + Express backend.
- MongoDB database.
- Use repositories/services; do not put business logic in UI.
- Keep User, Volunteer, and Admin features separated.
- Keep shared functionality in core/shared.
- Do not create duplicate role-independent widgets.
- Do not create multiple theme files.

## Theme rules
- Use `app_theme.dart` as the single design source.
- Never hardcode brand colors in screens.
- Never create one-off button/card/input styles unless the design system truly needs a new reusable variant.
- Follow the supplied healthcare UI references.

## API rules
- Never call backend endpoints directly from presentation widgets.
- Update API documentation when adding/changing an endpoint.
- Validate request and response data.
- Do not expose secrets.
- Do not silently change existing response contracts.

## Emergency rules
- Only VERIFIED + ACTIVE + available volunteers can be auto-assigned.
- BUSY/OFFLINE/unverified volunteers must be excluded.
- Acceptance timeout is 2 minutes.
- Acceptance must be atomic.
- Successful resolution returns volunteer to ACTIVE.
- Preserve assignment history.
- Never mark an emergency resolved without a valid resolution action.
- Never claim an alert was assigned when assignment failed.

## Location rules
- Treat location as sensitive.
- Track volunteer location only according to the documented Active/Busy behavior.
- Do not expose all volunteer locations to Users.
- Use routing through the routing abstraction.

## Medical feature rules
- Symptom checker is guidance/triage support, not a definitive diagnosis.
- Do not invent medical facts, drug dosages, or clinical protocols.
- Escalation wording must be cautious and safety-oriented.

## Localization rules
- User-facing text must use localization keys.
- English/Hindi/Marathi are required for User features.
- Do not hardcode strings in widgets.

## Code quality
- Prefer small focused files.
- Use meaningful names.
- Avoid unnecessary abstractions.
- Do not refactor unrelated files.
- Add tests for business-critical behavior.
- Remove dead code after a migration.
- Do not leave debug prints in production paths.

## Change protocol
For a significant feature:
1. Explain implementation plan.
2. Identify affected files.
3. Update relevant documentation.
4. Implement.
5. Test.
6. Summarize changes and remaining limitations.

## Never
- Replace Riverpod with another state-management library.
- create duplicate theme definitions.
- create duplicate reusable components.
- bypass backend authorization.
- store passwords in plaintext.
- put Cloudinary secrets in Flutter.
- expose sensitive location/document data unnecessarily.
