# MedAID — Project Documentation

> **Building or running the system?** Start with [`../README.md`](../README.md) for setup and
> [`../DEMO.md`](../DEMO.md) for the walkthrough. This folder is the specification; documents for
> areas that have been built end with a "V1 implementation" section describing what exists.

## Purpose
MedAID is a Flutter-based emergency health assistance platform designed for users in large gatherings such as Kumbh. The system connects Users, verified Volunteers, and Admins through symptom assistance, nearby medical facilities, one-tap emergency alerts, automated volunteer assignment, and emergency monitoring.

## Technology
- Frontend: Flutter
- State management: Riverpod
- Navigation: GoRouter
- Backend: Node.js + Express.js
- Database: MongoDB
- Authentication: JWT + email/username + password
- Document/media storage: Cloudinary
- Push notifications: Firebase Cloud Messaging
- Maps: OpenStreetMap
- Routing: OpenRouteService initially; routing provider must remain replaceable
- Shortest-path/assignment concept: Dijkstra/A* where a road graph is available
- Localization: English, Hindi, Marathi
- Theme: Light theme, one global theme source

## Roles
1. User
2. Volunteer
3. Admin

## Critical rule
Only VERIFIED and ACTIVE volunteers are eligible for automatic emergency assignment. BUSY and OFFLINE volunteers must never receive a new automatically assigned alert.

## Documentation index
- 01_PROJECT_OVERVIEW.md
- 02_SRS.md
- 03_FUNCTIONAL_REQUIREMENTS.md
- 04_NON_FUNCTIONAL_REQUIREMENTS.md
- 05_ROLES_AND_PERMISSIONS.md
- 06_USER_FLOWS.md
- 07_EMERGENCY_ASSIGNMENT_ENGINE.md
- 08_DATABASE_DESIGN.md
- 09_API_SPECIFICATION.md
- 10_SYSTEM_ARCHITECTURE.md
- 11_FLUTTER_ARCHITECTURE.md
- 12_BACKEND_ARCHITECTURE.md
- 13_FOLDER_STRUCTURE.md
- 14_STATE_MANAGEMENT.md
- 15_THEME_AND_DESIGN_SYSTEM.md
- 16_REUSABLE_WIDGETS.md
- 17_LOCALIZATION.md
- 18_MAPS_AND_LOCATION.md
- 19_NOTIFICATION_SYSTEM.md
- 20_VOLUNTEER_VERIFICATION.md
- 21_TEMPORARY_MEDICAL_CAMPS.md
- 22_SECURITY.md
- 23_ERROR_HANDLING.md
- 24_TESTING_STRATEGY.md
- 25_AI_DEVELOPMENT_RULES.md
- 26_IMPLEMENTATION_ROADMAP.md

UI references supplied by the project owner are the visual direction for the application: modern healthcare UI, light backgrounds, rounded cards, strong typography, pill/chip controls, generous spacing, simple navigation, and prominent primary actions. The emergency action must be more visually prominent than ordinary actions.
