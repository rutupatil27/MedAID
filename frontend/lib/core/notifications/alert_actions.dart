/// Ids for the buttons on an emergency alert.
///
/// They live in `core` rather than with the volunteer feature because the
/// background isolate answers these buttons with no app — and therefore no
/// feature layer — around it.
const acceptAction = 'assignment.accept';
const declineAction = 'assignment.decline';
