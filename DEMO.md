# MedAID — demo script

A 10-minute walkthrough of the whole system. It is written to be run twice in a row without
resetting anything: every step ends in a clean state.

## Before you start

```bash
cd backend
npm run seed:admin        # once, creates your admin account
npm run seed:demo         # repeatable: demo hospitals, camps, volunteers and one user
npm run dev
```

Then run the app on two devices or emulators (one User, one Volunteer), and keep the Admin
console open on a third or in the browser-free Flutter desktop build if you prefer:

```bash
cd frontend
flutter run    # set AppConfig.devApiBaseUrl to your backend address first
```

**Demo accounts** (password `DemoPass123`):

| Username | Role | State |
|---|---|---|
| `demo_asha` | User | — |
| `demo_ravi` | Volunteer | Verified, on duty, closest to Ramkund |
| `demo_sana` | Volunteer | Verified, on duty, ~1 km away |
| `demo_imran` | Volunteer | Verified, off duty |
| `demo_priya` | Volunteer | Awaiting verification |
| your admin | Admin | from `seed:admin` |

Set both devices' location to around Ramkund, Nashik (20.0086, 73.7925). On an Android emulator:
Extended controls → Location.

---

## 1. The user's side (2 min)

Sign in as `demo_asha`.

1. **Symptom checker** — pick "chest pain" and a duration. Point out that the guidance is
   conservative (it escalates rather than reassures), that it always offers "Call 112", and that
   it is guidance, not a diagnosis.
2. **Nearby help** — the map shows demo hospitals and **one** camp: "Demo Ramkund Relief Camp".
   The upcoming and finished camps are not shown; a camp only appears inside its validity window.
3. **Language** — switch to Hindi in Profile, then back. The whole User flow is translated.

## 2. An emergency, end to end (3 min)

1. On the volunteer device, sign in as `demo_ravi` and make sure the availability switch is on.
   The dashboard shows "Sharing live location".
2. On the user device, **press and hold the SOS button**. The alert is sent (it also works
   without a GPS fix, and pressing twice does not create two alerts).
3. Within a second or two the volunteer device shows the assignment with a **2-minute countdown**,
   the emergency location, the route and the ETA, and the reporter's details.
4. Accept it. The user's screen changes to "Help is on the way" with the responder and ETA, and
   the volunteer becomes BUSY.
5. Tap **I have arrived**, then **Mark as resolved** with a note.
6. The user sees the alert resolved and the volunteer returns to ACTIVE.

## 3. Nobody answers: reassignment (2 min)

This is the part worth showing carefully.

1. Make sure two volunteers are on duty: `demo_ravi` and `demo_sana` (sign in on a second
   device, or flip `demo_sana` on and leave `demo_ravi` idle on the assignment screen).
2. Raise another SOS as `demo_asha`.
3. The nearest volunteer receives it — **do not accept**.
4. After two minutes the assignment expires, and the alert moves to the next volunteer by itself.
   The expired volunteer sees "This assignment expired and was passed to another volunteer."
5. In the admin console the emergency shows both attempts in its history, and the admins have
   been notified of the timeout.

To show the "nobody available" case instead: switch every volunteer off duty and raise an SOS.
The alert becomes **UNASSIGNED**, the user is told help is still being sought (with a reminder to
call 112), and the admins are alerted. Switch a volunteer back on and it is picked up within
30 seconds.

## 4. The control room (3 min)

Sign in as your admin account.

1. **Dashboard** — live counts: open, waiting for a volunteer, in progress, today's total.
   Each card opens the matching filtered list.
2. **Emergencies** — open the alert from step 3. It shows the reporter, every assignment attempt
   with its outcome, and the timeline. Use **Reassign** to hand it to a chosen volunteer, or back
   to the engine.
3. **Volunteers** — `demo_priya` is waiting for review: open her, look at the documents, approve
   or reject with a reason. Suspension signs a volunteer out everywhere and hands back any
   emergency they hold.
4. **Tracking** — live positions, coloured by state: available, responding, or greyed out when
   their location is out of date.
5. **Camps** — create a camp by tapping the map, and show that it becomes visible to users only
   inside its window.
6. **More → Send notice to volunteers** — type a message; every verified volunteer receives it in
   their notification centre.
7. **Reports** — seven-day volumes, outcomes, average acceptance and resolution times, and the
   reassignment rate.

## Good things to say while demonstrating

- **Nothing is lost.** Every alert is either assigned, being reassigned, or in front of an admin.
  An alert without a volunteer is never shown as handled.
- **One responder per alert.** Acceptance is a single atomic database operation, and the database
  itself refuses a second active assignment, so two volunteers can never both "win".
- **It works when things fail.** No route provider: straight-line estimates, marked as estimates.
  No push: in-app notifications and polling. No GPS fix: the alert still goes out, and the control
  room is told.
- **Sensitive data stays scarce.** Notifications carry IDs, never names or medical details.
  Medical information reaches a volunteer only with the user's explicit consent, and a phone
  number only while they are actually responding.

## Resetting between runs

Nothing needs resetting: `npm run seed:demo` is repeatable, and demo accounts keep working.
If you want a clean slate, resolve or cancel any open alert from the admin console — a user can
only have one open alert at a time, which is deliberate.
