# 16 — Reusable Widgets

Build reusable components before duplicating UI.

## Required shared widgets
- AppScaffold
- AppHeader
- PrimaryButton
- SecondaryButton
- DangerButton / EmergencyButton
- AppTextField
- SearchField
- StatusChip
- LoadingView
- ErrorView
- EmptyStateView
- AppCard
- SectionHeader
- BottomNavBar
- ConfirmationDialog
- AppSnackbar
- ProfileAvatar
- FacilityCard
- MedicalCampCard
- EmergencyCard
- VolunteerStatusCard
- StatCard
- DocumentUploadTile
- LocationMap
- MapMarker abstraction
- PermissionPrompt
- LanguageSelector

## Reuse rule
Before creating a widget, search `core/widgets` and the current feature for an existing suitable component.

If the component will be used by multiple features, move/generalize it into shared widgets.

Avoid copy-pasting nearly identical cards/forms/buttons.
