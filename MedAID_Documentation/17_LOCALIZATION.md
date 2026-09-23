# 17 — Localization

Supported User languages:
- English: en
- Hindi: hi
- Marathi: mr

## Requirements
- No user-facing hardcoded strings in feature widgets.
- Use localization keys.
- Store translations centrally.
- Dates, times and messages should be locale-aware where appropriate.
- Error messages should have localized user-facing text.
- Backend error codes should remain language-neutral; Flutter maps them to localized messages.

## Suggested files
`lib/app/localization/`
- app_en.arb
- app_hi.arb
- app_mr.arb

The Admin and Volunteer interfaces may remain English in V1, while architecture should not prevent future localization.
