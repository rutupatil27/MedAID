# 20 — Volunteer Verification

## Account creation
1. Admin creates volunteer.
2. Backend creates user credentials with role VOLUNTEER.
3. Volunteer receives login information through the project's chosen secure delivery mechanism.
4. Volunteer logs in.
5. Volunteer completes personal profile.
6. Volunteer uploads required documents.
7. Verification status becomes PENDING.
8. Admin reviews.
9. Admin approves/rejects.
10. Approved volunteer can use emergency functions.

## Documents
Use Cloudinary for uploaded files. MongoDB stores metadata and secure URLs/public IDs.

## Security
- Validate file type and size.
- Do not trust filename extensions alone.
- Keep Cloudinary secrets only on backend.
- Restrict document access.
- Record review timestamps and reviewer ID.

## Rejection
Admin should provide a reason. Volunteer can replace/resubmit documents.

## Verification status
PENDING -> APPROVED
PENDING -> REJECTED
REJECTED -> PENDING after resubmission

Approval alone does not make a volunteer eligible if their operational status is Offline.
