// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MedAID';

  @override
  String get appTagline => 'Emergency health help for large gatherings';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonSave => 'Save';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get commonOk => 'OK';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonViewAll => 'View all';

  @override
  String get commonDetails => 'Details';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonNotAvailable => 'Not available';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSubtitle => 'Choose the language for the app';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageMarathi => 'मराठी';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork => 'No internet connection. Check your network and try again.';

  @override
  String get errorTimeout => 'The server is taking too long to respond. Please try again.';

  @override
  String get errorAuthInvalid => 'Incorrect email/username or password.';

  @override
  String get errorUnauthorized => 'Your session has ended. Please log in again.';

  @override
  String get errorForbidden => 'You do not have permission to do this.';

  @override
  String get errorAccountSuspended =>
      'This account is suspended. Please contact the administrator.';

  @override
  String get errorValidation => 'Please check the highlighted details.';

  @override
  String get errorNotFound => 'We couldn\'t find what you were looking for.';

  @override
  String get errorConflict => 'This action conflicts with the latest status. Please refresh.';

  @override
  String get errorRateLimited => 'Too many attempts. Please wait a moment and try again.';

  @override
  String get errorVolunteerNotVerified => 'Your volunteer verification is not approved yet.';

  @override
  String get errorVolunteerNotAvailable => 'You are not available for emergencies right now.';

  @override
  String get errorEmergencyAlreadyAssigned =>
      'This emergency has already been handled by someone else.';

  @override
  String get errorAssignmentExpired => 'This assignment has expired.';

  @override
  String get errorLocationUnavailable =>
      'Your location is unavailable. Turn on location services and try again.';

  @override
  String get errorRoutingUnavailable => 'Route information is unavailable right now.';

  @override
  String get errorFileUploadFailed => 'The file could not be uploaded. Please try again.';

  @override
  String get errorInternal => 'A server error occurred. Please try again shortly.';

  @override
  String get authLoginTitle => 'Welcome back';

  @override
  String get authLoginSubtitle => 'Log in to get help quickly when you need it.';

  @override
  String get authIdentifierLabel => 'Email or username';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authLoginButton => 'Log in';

  @override
  String get authNoAccount => 'New to MedAID?';

  @override
  String get authCreateAccountLink => 'Create an account';

  @override
  String get authStaffNote => 'Volunteers and admins: use the account created for you.';

  @override
  String get authRegisterTitle => 'Create your account';

  @override
  String get authRegisterSubtitle => 'It takes less than a minute.';

  @override
  String get authNameLabel => 'Full name';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authUsernameLabel => 'Username';

  @override
  String get authPhoneLabel => 'Phone number (optional)';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authRegisterButton => 'Create account';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authLoginLink => 'Log in';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authLogout => 'Log out';

  @override
  String get authLogoutConfirmTitle => 'Log out?';

  @override
  String get authLogoutConfirmMessage => 'You will need to log in again to use MedAID.';

  @override
  String get authChangePasswordTitle => 'Set a new password';

  @override
  String get authChangePasswordSubtitle =>
      'For your security, choose a new password before continuing.';

  @override
  String get authCurrentPasswordLabel => 'Current password';

  @override
  String get authNewPasswordLabel => 'New password';

  @override
  String get authChangePasswordButton => 'Update password';

  @override
  String get authPasswordChanged => 'Your password has been updated.';

  @override
  String get authAccountCreated => 'Welcome to MedAID!';

  @override
  String get validationRequired => 'This field is required.';

  @override
  String get validationEmail => 'Enter a valid email address.';

  @override
  String get validationUsername => 'Use 3–30 letters, numbers, dots or underscores.';

  @override
  String get validationPassword => 'Use at least 8 characters, including letters and numbers.';

  @override
  String get validationPasswordMismatch => 'Passwords do not match.';

  @override
  String get validationPasswordSame => 'The new password must be different.';

  @override
  String get validationPhone => 'Enter a valid phone number.';

  @override
  String get validationName => 'Enter your full name.';

  @override
  String get errorPasswordChangeRequired => 'Please set a new password to continue.';

  @override
  String homeGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get commonClear => 'Clear';

  @override
  String get commonAllow => 'Allow';

  @override
  String get commonOpenSettings => 'Open settings';

  @override
  String get commonUpload => 'Upload';

  @override
  String get commonReplace => 'Replace';

  @override
  String get authAccountExists => 'This email or username is already in use.';

  @override
  String get navHome => 'Home';

  @override
  String get navFacilities => 'Nearby';

  @override
  String get navEmergencies => 'Alerts';

  @override
  String get navProfile => 'Profile';

  @override
  String get commonCallEmergency => 'Call 112';

  @override
  String get commonNotSet => 'Not set';

  @override
  String get homeSubtitle => 'Help is one button away.';

  @override
  String get sosLabel => 'SOS';

  @override
  String get sosHoldHint => 'Hold for help';

  @override
  String get sosSemanticLabel => 'Send an emergency alert';

  @override
  String get sosCardTitle => 'In an emergency?';

  @override
  String get sosCardBody =>
      'Press and hold the button. We will share your location with the nearest volunteer.';

  @override
  String get homeActiveAlertTitle => 'You have an active alert';

  @override
  String get homeActiveAlertAction => 'View status';

  @override
  String get homeQuickActions => 'What do you need?';

  @override
  String get homeSymptomsTitle => 'Check symptoms';

  @override
  String get homeSymptomsSubtitle => 'Get general guidance';

  @override
  String get homeFacilitiesTitle => 'Hospitals & camps';

  @override
  String get homeFacilitiesSubtitle => 'Find help near you';

  @override
  String get homeHistoryTitle => 'My alerts';

  @override
  String get homeHistorySubtitle => 'Status and history';

  @override
  String get sosSendingTitle => 'Sending your alert';

  @override
  String get sosStepLocating => 'Getting your location…';

  @override
  String get sosStepSending => 'Alerting volunteers…';

  @override
  String get sosFailedTitle => 'Alert not sent';

  @override
  String get sosFailedMessage => 'We could not send your alert. Try again, or call 112 now.';

  @override
  String get sosNoLocationWarning =>
      'We could not get your location, so the control room has been alerted. If you can, call 112.';

  @override
  String get emergencyStatusCreated => 'Alert sent';

  @override
  String get emergencyStatusAssigning => 'Finding a volunteer';

  @override
  String get emergencyStatusAssigned => 'Contacting a volunteer';

  @override
  String get emergencyStatusAccepted => 'Help is on the way';

  @override
  String get emergencyStatusInProgress => 'Responder with you';

  @override
  String get emergencyStatusResolved => 'Resolved';

  @override
  String get emergencyStatusCancelled => 'Cancelled';

  @override
  String get emergencyStatusExpired => 'Closed';

  @override
  String get emergencyStatusUnassigned => 'Waiting for a volunteer';

  @override
  String get emergencyReasonNoLocation => 'No location was available';

  @override
  String get emergencyReasonNoVolunteer => 'No volunteer available nearby';

  @override
  String get emergencyReasonCandidatesBusy => 'Nearby volunteers were busy';

  @override
  String get emergencyReasonVolunteerUnavailable => 'The volunteer became unavailable';

  @override
  String get emergencyReasonTimeout => 'No answer in time';

  @override
  String get emergencyReasonDeclined => 'The volunteer could not come';

  @override
  String get emergencyReasonAdminReassigned => 'Reassigned by the control room';

  @override
  String get emergencyMessageSearching =>
      'We are finding the nearest available volunteer. Stay where you are if it is safe.';

  @override
  String emergencyMessageAccepted(String name) {
    return '$name accepted your alert and is coming to you.';
  }

  @override
  String get emergencyMessageAcceptedNoName =>
      'A volunteer accepted your alert and is coming to you.';

  @override
  String get emergencyMessageInProgress => 'Your responder has reached you.';

  @override
  String get emergencyMessageUnassigned =>
      'No volunteer is free right now. The control room has been alerted and we keep trying. If you can, call 112.';

  @override
  String get emergencyMessageResolved =>
      'This alert has been resolved. We hope you are feeling better.';

  @override
  String get emergencyMessageCancelled => 'This alert was cancelled.';

  @override
  String emergencyEta(int minutes) {
    return 'About $minutes min away';
  }

  @override
  String get emergencyDetailTitle => 'Emergency alert';

  @override
  String get emergencyTimelineTitle => 'Timeline';

  @override
  String get emergencyYourLocation => 'Your shared location';

  @override
  String get emergencyNoLocation => 'Location not shared';

  @override
  String get emergencyCancelAction => 'Cancel alert';

  @override
  String get emergencyCancelConfirmTitle => 'Cancel this alert?';

  @override
  String get emergencyCancelConfirmMessage =>
      'Only cancel if you no longer need help. A volunteer on the way will be told to stop.';

  @override
  String get emergencyKeepAlert => 'Keep alert';

  @override
  String get emergencyCancelled => 'Your alert was cancelled.';

  @override
  String get emergencyHistoryEmptyTitle => 'No alerts yet';

  @override
  String get emergencyHistoryEmptyMessage => 'Alerts you send will appear here.';

  @override
  String get emergencyLiveUpdates => 'Updates automatically';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String distanceMeters(String meters) {
    return '$meters m';
  }

  @override
  String distanceKilometers(String km) {
    return '$km km';
  }

  @override
  String get symptomsTitle => 'Symptom checker';

  @override
  String get symptomsSubtitle => 'Select everything you are experiencing.';

  @override
  String get symptomsSearchHint => 'Search symptoms';

  @override
  String get symptomsAboutYou => 'About the person';

  @override
  String get symptomsAgeYoungChild => 'Under 5';

  @override
  String get symptomsAgeChild => '5–17 years';

  @override
  String get symptomsAgeAdult => '18–64 years';

  @override
  String get symptomsAgeOlder => '65 or older';

  @override
  String get symptomsPregnant => 'Pregnant';

  @override
  String get symptomsDurationLabel => 'How long?';

  @override
  String get symptomsDurationToday => 'Today';

  @override
  String get symptomsDurationFewDays => '1–2 days';

  @override
  String get symptomsDurationLonger => '3+ days';

  @override
  String get symptomsCheckButton => 'Get guidance';

  @override
  String symptomsSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get symptomsEmergencyShortcut => 'Severe symptoms? Don\'t wait — use SOS.';

  @override
  String get symptomsNoMatch => 'No symptoms match your search.';

  @override
  String get symptomsResultTitle => 'Your guidance';

  @override
  String get symptomsWhatToDo => 'What to do now';

  @override
  String get symptomsWarningSignsTitle => 'Use SOS right away if you notice';

  @override
  String get symptomsSelectedTitle => 'Symptoms you selected';

  @override
  String get symptomsFindFacility => 'Find nearest hospital or camp';

  @override
  String get symptomsUseSos => 'Send SOS alert';

  @override
  String get symptomsStartOver => 'Check again';

  @override
  String get triageEmergency => 'Emergency';

  @override
  String get triageUrgent => 'Urgent';

  @override
  String get triageRoutine => 'Not urgent';

  @override
  String get facilitiesTitle => 'Nearby help';

  @override
  String get facilitiesSubtitle => 'Hospitals and medical camps near you';

  @override
  String get facilitiesFilterAll => 'All';

  @override
  String get facilitiesFilterHospitals => 'Hospitals';

  @override
  String get facilitiesFilterCamps => 'Medical camps';

  @override
  String get facilitiesViewList => 'List';

  @override
  String get facilitiesViewMap => 'Map';

  @override
  String get facilityTypeHospital => 'Hospital';

  @override
  String get facilityTypeCamp => 'Medical camp';

  @override
  String get facilityEmergencyDept => 'Emergency care';

  @override
  String facilityOpenUntil(String time) {
    return 'Open until $time';
  }

  @override
  String get facilitiesEmptyTitle => 'Nothing found nearby';

  @override
  String get facilitiesEmptyMessage => 'Try another filter, or use SOS if you need urgent help.';

  @override
  String get facilityServicesTitle => 'Services';

  @override
  String get facilityAddressTitle => 'Address';

  @override
  String get facilityContactTitle => 'Contact';

  @override
  String get facilityCall => 'Call';

  @override
  String get facilityDirections => 'Directions';

  @override
  String get facilityValidityTitle => 'Open hours';

  @override
  String get facilityAbout => 'About';

  @override
  String get locationPermissionTitle => 'Allow location access';

  @override
  String get locationPermissionMessage =>
      'MedAID uses your location to show help nearby and to guide volunteers to you in an emergency.';

  @override
  String get locationServicesOffTitle => 'Turn on location';

  @override
  String get locationServicesOffMessage => 'Location services are off on this phone.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profilePersonalDetails => 'Personal details';

  @override
  String get profileMedicalInfo => 'Medical information';

  @override
  String get profileMedicalInfoSubtitle => 'Shared with responders only if you allow it';

  @override
  String get profileEditTitle => 'Edit details';

  @override
  String get profileSaved => 'Your changes were saved.';

  @override
  String get profileChangePassword => 'Change password';

  @override
  String get medicalDob => 'Date of birth';

  @override
  String get medicalGender => 'Gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get genderPreferNotToSay => 'Prefer not to say';

  @override
  String get medicalBloodGroup => 'Blood group';

  @override
  String get bloodGroupUnknown => 'Don\'t know';

  @override
  String get medicalAllergies => 'Allergies';

  @override
  String get medicalConditions => 'Existing medical conditions';

  @override
  String get medicalEmergencyContactName => 'Emergency contact name';

  @override
  String get medicalEmergencyContactPhone => 'Emergency contact phone';

  @override
  String get medicalShareConsent =>
      'Share this information with the volunteer who responds to my alert';

  @override
  String get medicalShareConsentHelp =>
      'Only the assigned volunteer and administrators can see it, and only during an alert.';

  @override
  String get medicalOptionalNote => 'All fields are optional.';

  @override
  String get errorFileTooLarge => 'This file is larger than 5 MB. Please choose a smaller file.';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get verificationNotSubmitted => 'Not submitted';

  @override
  String get verificationPending => 'Under review';

  @override
  String get verificationApproved => 'Verified';

  @override
  String get verificationRejected => 'Not approved';

  @override
  String get volunteerStatusActive => 'Active';

  @override
  String get volunteerStatusOffline => 'Offline';

  @override
  String get volunteerStatusBusy => 'Busy';

  @override
  String get documentTypeIdProof => 'ID proof';

  @override
  String get documentTypeFirstAid => 'First-aid certificate';

  @override
  String get documentTypeOther => 'Other document';

  @override
  String get documentStatusPending => 'Under review';

  @override
  String get documentStatusApproved => 'Approved';

  @override
  String get documentStatusRejected => 'Rejected';

  @override
  String get assignmentPending => 'Awaiting your response';

  @override
  String get assignmentAccepted => 'Accepted';

  @override
  String get assignmentDeclined => 'Declined';

  @override
  String get assignmentExpired => 'Expired';

  @override
  String get assignmentCancelled => 'Cancelled';

  @override
  String get assignmentCompleted => 'Completed';

  @override
  String get volunteerDashboardSubtitle => 'Thank you for helping keep people safe.';

  @override
  String get volunteerOnboardingTitle => 'Finish setting up';

  @override
  String get volunteerOnboardingSubtitle => 'Complete these steps to start receiving emergencies.';

  @override
  String get volunteerStepProfile => 'Complete your profile';

  @override
  String get volunteerStepDocuments => 'Upload verification documents';

  @override
  String get volunteerStepVerification => 'Admin approval';

  @override
  String get volunteerAvailabilityTitle => 'Availability';

  @override
  String get volunteerAvailabilityActiveMessage => 'You will receive nearby emergencies.';

  @override
  String get volunteerAvailabilityOfflineMessage => 'Go active to receive emergencies.';

  @override
  String get volunteerAvailabilityBusyMessage =>
      'Resolve your current emergency to receive new ones.';

  @override
  String get volunteerAvailabilitySwitch => 'Available for emergencies';

  @override
  String get volunteerCurrentAssignment => 'Current emergency';

  @override
  String get volunteerNoAssignmentTitle => 'No emergencies right now';

  @override
  String get volunteerNoAssignmentMessage =>
      'Stay active. New emergencies near you will appear here.';

  @override
  String volunteerRespondWithin(String time) {
    return 'Respond within $time';
  }

  @override
  String get volunteerEmergenciesTitle => 'Emergencies';

  @override
  String get volunteerActiveTab => 'Active';

  @override
  String get volunteerHistoryTab => 'History';

  @override
  String get volunteerHistoryEmpty => 'Emergencies you respond to will appear here.';

  @override
  String get volunteerEmergencyTitle => 'Emergency';

  @override
  String get volunteerReporterTitle => 'Person in need';

  @override
  String get volunteerCallReporter => 'Call';

  @override
  String get volunteerMedicalInfoTitle => 'Shared medical information';

  @override
  String get volunteerNoMedicalInfo => 'No medical information shared.';

  @override
  String get volunteerLocationTitle => 'Emergency location';

  @override
  String get volunteerNoLocation =>
      'The person could not share a location. Call them or contact the control room.';

  @override
  String get volunteerAccept => 'Accept emergency';

  @override
  String get volunteerDecline => 'Decline';

  @override
  String get volunteerDeclineConfirmTitle => 'Decline this emergency?';

  @override
  String get volunteerDeclineConfirmMessage => 'It will be sent to the next available volunteer.';

  @override
  String get volunteerStartAssistance => 'I have arrived';

  @override
  String get volunteerResolve => 'Mark as resolved';

  @override
  String get volunteerResolveTitle => 'Resolve emergency';

  @override
  String get volunteerResolveNoteLabel => 'What help was given?';

  @override
  String get volunteerResolveNoteHint => 'e.g. First aid given, escorted to the medical camp';

  @override
  String get volunteerResolved => 'Emergency resolved. You are active again.';

  @override
  String get volunteerAccepted => 'Accepted. The person has been told help is coming.';

  @override
  String get volunteerExpiredMessage =>
      'This assignment expired and was passed to another volunteer.';

  @override
  String get volunteerClosedMessage => 'This emergency is closed.';

  @override
  String get volunteerDirections => 'Directions';

  @override
  String volunteerRouteEta(int minutes, String distance) {
    return '$minutes min · $distance';
  }

  @override
  String get volunteerRouteEstimated =>
      'Estimated from straight-line distance. The walking route may be longer.';

  @override
  String get volunteerRouteUnavailable =>
      'Route unavailable right now. Use Directions to navigate.';

  @override
  String get trackingNotificationTitle => 'MedAID is sharing your location';

  @override
  String get trackingNotificationText => 'Used to send you nearby emergencies. Go offline to stop.';

  @override
  String get trackingStarting => 'Starting live location…';

  @override
  String trackingActive(String time) {
    return 'Sharing live location · $time';
  }

  @override
  String get trackingOffTitle => 'Location sharing is off';

  @override
  String get trackingPermissionMessage =>
      'Allow location access, or you will stop receiving nearby emergencies within a few minutes.';

  @override
  String get trackingServicesOffMessage =>
      'Turn on location services, or you will stop receiving nearby emergencies within a few minutes.';

  @override
  String get volunteerResolutionTitle => 'Resolution';

  @override
  String get profileCompleteTitle => 'Your details';

  @override
  String get profileCompleteSubtitle => 'Admins use these details to verify you.';

  @override
  String get volunteerAddress => 'Address';

  @override
  String get volunteerCity => 'City';

  @override
  String get volunteerPhone => 'Phone number';

  @override
  String get volunteerSkills => 'Skills (comma separated)';

  @override
  String get volunteerLanguages => 'Languages you speak (comma separated)';

  @override
  String get documentsTitle => 'Verification documents';

  @override
  String get documentsSubtitle => 'Upload a clear photo or PDF of each document. Maximum 5 MB.';

  @override
  String get documentUploaded => 'Document uploaded.';

  @override
  String get documentsSubmitted => 'Documents submitted for review.';

  @override
  String get verificationTitle => 'Verification';

  @override
  String get verificationPendingMessage =>
      'An administrator is reviewing your documents. You will be notified when it\'s done.';

  @override
  String get verificationApprovedMessage =>
      'You are verified. Go active from the dashboard to start receiving emergencies.';

  @override
  String get verificationRejectedMessage =>
      'Your verification was not approved. Please update your documents.';

  @override
  String get verificationNotSubmittedMessage =>
      'Complete your profile and upload the required documents.';

  @override
  String get verificationReasonLabel => 'Reason';

  @override
  String get verificationUpdateDocuments => 'Update documents';

  @override
  String get volunteerProfileDocuments => 'Documents';

  @override
  String get navVolunteers => 'Volunteers';

  @override
  String get navCamps => 'Camps';

  @override
  String get navMore => 'More';

  @override
  String get adminDashboardTitle => 'Control room';

  @override
  String get adminDashboardSubtitle => 'Live overview of emergencies and volunteers';

  @override
  String get adminStatOpen => 'Open emergencies';

  @override
  String get adminStatUnassigned => 'Waiting for a volunteer';

  @override
  String get adminStatAwaiting => 'Awaiting acceptance';

  @override
  String get adminStatInProgress => 'Help on the way';

  @override
  String get adminStatToday => 'Alerts today';

  @override
  String get adminStatPendingVerification => 'Pending verifications';

  @override
  String get adminStatActiveVolunteers => 'Active volunteers';

  @override
  String get adminStatBusyVolunteers => 'Busy volunteers';

  @override
  String get adminStatActiveCamps => 'Camps open now';

  @override
  String get adminRecentOpen => 'Open emergencies';

  @override
  String get adminNoOpenEmergencies => 'No open emergencies right now.';

  @override
  String get adminFilterOpen => 'Open';

  @override
  String get adminFilterAll => 'All';

  @override
  String get adminFilterUnassigned => 'Unassigned';

  @override
  String get adminFilterResolved => 'Resolved';

  @override
  String get adminSearchAlert => 'Search alert number';

  @override
  String get adminEmergenciesEmpty => 'No emergencies match this filter.';

  @override
  String get adminReporter => 'Reported by';

  @override
  String get adminAssignedVolunteer => 'Assigned volunteer';

  @override
  String get adminNotAssigned => 'No volunteer assigned';

  @override
  String adminAttempts(int count) {
    return 'Attempts: $count';
  }

  @override
  String get adminAssignmentHistory => 'Assignment history';

  @override
  String get adminNoAssignments => 'No dispatch attempts yet.';

  @override
  String get adminReassign => 'Find another volunteer';

  @override
  String get adminReassignTo => 'Assign to a volunteer';

  @override
  String get adminReassignConfirmTitle => 'Reassign this emergency?';

  @override
  String get adminReassignConfirmMessage =>
      'The current volunteer will be released and the emergency dispatched again.';

  @override
  String get adminReassigned => 'Emergency sent for reassignment.';

  @override
  String get adminResolve => 'Resolve';

  @override
  String get adminCancelEmergency => 'Cancel emergency';

  @override
  String get adminCloseNoteLabel => 'Note (required)';

  @override
  String get adminClosed => 'Emergency closed.';

  @override
  String get adminPickVolunteer => 'Choose a volunteer';

  @override
  String get adminNoEligibleVolunteers => 'No active, verified volunteers are available.';

  @override
  String get adminVolunteersTitle => 'Volunteers';

  @override
  String get adminVolunteersEmpty => 'No volunteers match this filter.';

  @override
  String get adminSearchVolunteers => 'Search by name, email or username';

  @override
  String get adminFilterPendingVerification => 'Pending review';

  @override
  String get adminCreateVolunteer => 'Add volunteer';

  @override
  String get adminCreateVolunteerSubtitle =>
      'The volunteer signs in with a temporary password and must change it.';

  @override
  String get adminVolunteerCreatedTitle => 'Volunteer created';

  @override
  String adminTemporaryPasswordMessage(String name) {
    return 'Share this temporary password with $name in person. It will not be shown again.';
  }

  @override
  String get adminCopy => 'Copy';

  @override
  String get adminCopied => 'Copied to clipboard.';

  @override
  String get adminVolunteerDetails => 'Volunteer';

  @override
  String get adminProfileSection => 'Profile';

  @override
  String get adminDocumentsSection => 'Documents';

  @override
  String get adminNoDocuments => 'No documents uploaded yet.';

  @override
  String get adminViewDocument => 'View';

  @override
  String get adminApprove => 'Approve';

  @override
  String get adminReject => 'Reject';

  @override
  String get adminRejectReasonLabel => 'Reason for rejection';

  @override
  String get adminApproved => 'Volunteer approved.';

  @override
  String get adminRejected => 'Volunteer rejected.';

  @override
  String get adminSuspend => 'Suspend account';

  @override
  String get adminReactivate => 'Reactivate account';

  @override
  String get adminSuspendConfirmTitle => 'Suspend this account?';

  @override
  String get adminSuspendConfirmMessage =>
      'They will be signed out immediately. Any emergency they hold will be reassigned.';

  @override
  String get adminSuspended => 'Suspended';

  @override
  String get adminAccountUpdated => 'Account updated.';

  @override
  String get adminLastLocation => 'Last location update';

  @override
  String get adminTrackingTitle => 'Volunteer tracking';

  @override
  String get adminTrackingSubtitle => 'Active and busy volunteers';

  @override
  String get adminTrackingEmpty => 'No volunteers are sharing a location right now.';

  @override
  String adminTrackingAvailable(int count) {
    return '$count available';
  }

  @override
  String adminTrackingResponding(int count) {
    return '$count responding';
  }

  @override
  String adminTrackingStale(int count) {
    return '$count location out of date';
  }

  @override
  String get adminCampsTitle => 'Medical camps';

  @override
  String get adminCampsEmpty => 'No camps match this filter.';

  @override
  String get adminCreateCamp => 'Add camp';

  @override
  String get adminEditCamp => 'Edit camp';

  @override
  String get adminCampName => 'Camp name';

  @override
  String get adminCampDescription => 'Description';

  @override
  String get adminCampAddress => 'Address';

  @override
  String get adminCampServices => 'Services (comma separated)';

  @override
  String get adminCampContactName => 'Contact person';

  @override
  String get adminCampContactPhone => 'Contact phone';

  @override
  String get adminCampStart => 'Opens';

  @override
  String get adminCampEnd => 'Closes';

  @override
  String get adminCampActive => 'Active';

  @override
  String get adminCampLocation => 'Location';

  @override
  String get adminCampLocationHint => 'Tap the map to place the camp.';

  @override
  String get adminCampUseMyLocation => 'Use my location';

  @override
  String get adminCampLocationRequired => 'Choose the camp location on the map.';

  @override
  String get adminCampEndBeforeStart => 'The closing time must be after the opening time.';

  @override
  String get adminCampSaved => 'Camp saved.';

  @override
  String get adminCampDelete => 'Delete camp';

  @override
  String get adminCampDeleteConfirm => 'Users will no longer see this camp.';

  @override
  String get adminCampDeleted => 'Camp deleted.';

  @override
  String get campLifecycleActiveNow => 'Open now';

  @override
  String get campLifecycleUpcoming => 'Upcoming';

  @override
  String get campLifecycleExpired => 'Ended';

  @override
  String get campLifecycleInactive => 'Inactive';

  @override
  String get adminUsersTitle => 'Users';

  @override
  String get adminUsersEmpty => 'No users match this filter.';

  @override
  String get adminSearchUsers => 'Search users';

  @override
  String get roleUser => 'User';

  @override
  String get roleVolunteer => 'Volunteer';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get adminReportsTitle => 'Reports';

  @override
  String get adminReportsSubtitle => 'Last 7 days';

  @override
  String get adminReportTotal => 'Alerts';

  @override
  String get adminReportResolved => 'Resolved';

  @override
  String get adminReportCancelled => 'Cancelled';

  @override
  String get adminReportReassignment => 'Needed reassignment';

  @override
  String get adminReportAvgAccept => 'Avg. time to accept';

  @override
  String get adminReportAvgResolve => 'Avg. time to resolve';

  @override
  String get adminReportPerDay => 'Alerts per day';

  @override
  String get adminReportNoData => 'No alerts in this period.';

  @override
  String adminMinutes(int count) {
    return '$count min';
  }

  @override
  String get adminSettingsTitle => 'Settings';

  @override
  String get adminMoreTitle => 'More';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmptyTitle => 'No notifications yet';

  @override
  String get notificationsEmptyMessage =>
      'Updates about emergencies and your account will appear here.';

  @override
  String get notificationsMarkAllRead => 'Mark all read';

  @override
  String get notificationsUnread => 'Unread';

  @override
  String notificationsBellLabel(int count) {
    return 'Notifications, $count unread';
  }

  @override
  String get notificationsBadgeMax => '99+';

  @override
  String get adminNoticeTitle => 'Send notice to volunteers';

  @override
  String get adminNoticeSubtitle => 'Reaches every verified volunteer';

  @override
  String get adminNoticeLabel => 'Message';

  @override
  String get adminNoticeHint => 'e.g. Ghat 4 is closed; use the north entrance.';

  @override
  String get adminNoticeSend => 'Send notice';

  @override
  String adminNoticeSent(int count) {
    return 'Notice sent to $count volunteers.';
  }

  @override
  String get symptomsFirstAidTitle => 'First aid you can give now';

  @override
  String get exitConfirmTitle => 'Leave MedAID?';

  @override
  String get exitConfirmMessage => 'You can reopen the app any time. Your alerts stay active.';

  @override
  String get exitConfirmAction => 'Leave';

  @override
  String get adminDocumentZoomHint => 'Pinch to zoom, drag to move';

  @override
  String get adminDocumentLoadFailed =>
      'The document could not be loaded. The link expires after a few minutes — go back and open it again.';

  @override
  String get adminDocumentPdfNotice => 'This is a PDF. The app cannot display PDF pages yet.';

  @override
  String get adminDocumentOpenExternally => 'Open outside the app';

  @override
  String get adminDocumentUnavailableTitle => 'Nothing to show';

  @override
  String get adminDocumentUnavailableMessage =>
      'Open a document from the volunteer\'s documents list.';

  @override
  String get volunteerAlertNotificationTitle => 'New emergency near you';

  @override
  String get volunteerAlertNotificationBody => 'Open MedAID and respond within 2 minutes.';
}
