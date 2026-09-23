# 11 — Flutter Architecture

Use a feature-first architecture with role separation.

Layers:
- presentation: screens/widgets
- application: Riverpod providers/controllers/notifiers
- domain: entities/models/use-case abstractions
- data: repositories, API services, DTOs
- core: theme, routing, localization, network, utilities

## Rules
- Screens should orchestrate UI, not contain API calls.
- Providers expose state to widgets.
- Repositories abstract data access.
- Models/DTOs handle serialization.
- Common UI belongs in shared widgets.
- Role-specific features stay under their role folder.
- Global theme is the only source of design tokens.
