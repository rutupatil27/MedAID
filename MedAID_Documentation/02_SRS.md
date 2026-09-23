# 02 — Software Requirements Specification (SRS)

## 1. Introduction
MedAID is a mobile-first emergency health assistance system for large gatherings.

## 2. User classes
### User
A person attending the gathering who can obtain health guidance, find medical facilities, and raise emergency alerts.

### Volunteer
A registered helper who must complete profile information and upload verification documents. The Admin verifies the volunteer before emergency functions become available.

### Admin
Manages volunteers, emergencies, temporary camps, and system monitoring.

## 3. Functional requirements
### FR-01 Authentication
The system shall support registration/login using email or username and password. JWT shall protect authenticated APIs.

### FR-02 User profile
Users shall be able to manage their basic profile information.

### FR-03 Symptom checker
Users shall be able to enter symptoms and receive general guidance/triage output.

### FR-04 Nearby facilities
Users shall see nearby hospitals and currently active temporary medical camps on a map/list.

### FR-05 SOS
Users shall have a one-tap emergency action that creates an alert containing the user's current location and relevant basic information.

### FR-06 Alert lifecycle
An alert shall move through defined states and maintain timestamps and assignment history.

### FR-07 Volunteer onboarding
Admin shall create a volunteer account. The volunteer shall complete personal details and upload required documents.

### FR-08 Verification
Admin shall approve or reject submitted volunteer documents.

### FR-09 Volunteer availability
Verified volunteers shall be able to set Active or Offline. When responding to an alert they become Busy.

### FR-10 Automatic assignment
Only verified active volunteers with usable location data shall be eligible. Busy/offline/unverified volunteers shall be excluded.

### FR-11 Acceptance timeout
A dispatched alert shall have a 2-minute acceptance window. If not accepted, the assignment shall expire and the scheduler shall attempt reassignment.

### FR-12 Resolution
The assigned volunteer shall resolve the alert after assistance is provided. On successful resolution, the volunteer becomes Active automatically.

### FR-13 Admin monitoring
Admin shall see active alerts, assignment state, volunteer status, assignment history, and resolution information.

### FR-14 Localization
User-facing application content shall support English, Hindi, and Marathi.

### FR-15 Temporary camps
Admin shall create, update, activate/deactivate, and schedule temporary medical camps. The User map shall show camps valid for the current date/time.

## 4. Key constraints
- One global theme source.
- Riverpod for application state.
- Reusable widgets/components.
- API logic must not be embedded directly in presentation widgets.
- Role-specific code must remain separated.
- Backend authorization must enforce role permissions; UI hiding alone is insufficient.

## 5. Assumptions
- Users have location permission when using emergency/map features.
- Volunteers grant location permission while Active/Busy.
- Routing provider availability can vary; assignment must fail safely.
