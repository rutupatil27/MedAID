# 01 — Project Overview

## Problem
During very large gatherings, people may have difficulty finding nearby medical facilities or obtaining quick assistance during an emergency. Volunteer response can also become inefficient if alerts are handled manually.

## Proposed solution
MedAID provides:
- Symptom checker/triage guidance
- Nearby hospitals and temporary medical camps
- One-tap SOS
- GPS-based emergency alert creation
- Automated assignment to eligible volunteers
- Volunteer acceptance and resolution workflow
- Admin monitoring and volunteer management
- Multilingual User experience

## Core emergency model
User SOS -> Alert created -> eligibility filtering -> nearest/fastest eligible volunteer -> notification -> acceptance -> BUSY -> assistance -> resolution -> ACTIVE.

## Scope
The first version focuses on emergency coordination rather than appointment booking, QR health IDs, or a full hospital management system.

## Out of scope for V1
- QR Health ID
- Doctor role
- Appointment booking
- Payments
- Ambulance fleet management
- Full electronic medical records
- Production-grade autonomous diagnosis

The symptom feature must be presented as guidance/triage support, not a definitive diagnosis.
