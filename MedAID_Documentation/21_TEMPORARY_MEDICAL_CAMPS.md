# 21 — Temporary Medical Camps

## Purpose
Support temporary medical facilities that exist only during a gathering/event.

## Admin
Admin can:
- create camp
- edit camp
- activate/deactivate camp
- define validity period
- define services
- define contact information
- view camp on map

## Fields
- name
- description
- GPS location
- address
- services
- contact
- start date/time
- end date/time
- active status

## User behavior
When User opens nearby medical facilities:
- query nearby hospitals
- query nearby camps valid at current time
- display both on map/list
- allow facility details

## Expiry
A camp should automatically be considered inactive after endDateTime even if `isActive` remains true. Backend query logic must enforce the time window.

## Future
The same model can support temporary first-aid posts, vaccination booths, hydration points, or other event facilities if required later.
