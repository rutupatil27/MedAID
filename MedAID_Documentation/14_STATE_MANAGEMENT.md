# 14 — State Management

Riverpod is the required state-management solution.

## Provider categories
- authProvider
- userProfileProvider
- symptomCheckerProvider
- facilitiesProvider
- emergencyProvider
- volunteerProfileProvider
- volunteerAvailabilityProvider
- assignedEmergenciesProvider
- volunteerLocationProvider
- adminDashboardProvider
- adminVolunteersProvider
- adminEmergenciesProvider
- medicalCampsProvider
- notificationProvider
- localeProvider

## Rules
- Use AsyncValue for async loading/error/data states where appropriate.
- Avoid global mutable singleton state.
- Keep provider responsibilities focused.
- Do not put large UI trees inside providers.
- Dispose location listeners when the relevant lifecycle ends.
- Do not duplicate API calls in multiple screens; centralize through repositories/providers.
