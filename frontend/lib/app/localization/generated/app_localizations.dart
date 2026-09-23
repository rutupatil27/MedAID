import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('hi'), Locale('mr')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'MedAID'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Emergency health help for large gatherings'**
  String get appTagline;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get commonViewAll;

  /// No description provided for @commonDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get commonDetails;

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// No description provided for @commonNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get commonNotAvailable;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the language for the app'**
  String get languageSubtitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get languageHindi;

  /// No description provided for @languageMarathi.
  ///
  /// In en, this message translates to:
  /// **'मराठी'**
  String get languageMarathi;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network and try again.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server is taking too long to respond. Please try again.'**
  String get errorTimeout;

  /// No description provided for @errorAuthInvalid.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email/username or password.'**
  String get errorAuthInvalid;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Please log in again.'**
  String get errorUnauthorized;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to do this.'**
  String get errorForbidden;

  /// No description provided for @errorAccountSuspended.
  ///
  /// In en, this message translates to:
  /// **'This account is suspended. Please contact the administrator.'**
  String get errorAccountSuspended;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Please check the highlighted details.'**
  String get errorValidation;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find what you were looking for.'**
  String get errorNotFound;

  /// No description provided for @errorConflict.
  ///
  /// In en, this message translates to:
  /// **'This action conflicts with the latest status. Please refresh.'**
  String get errorConflict;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get errorRateLimited;

  /// No description provided for @errorVolunteerNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Your volunteer verification is not approved yet.'**
  String get errorVolunteerNotVerified;

  /// No description provided for @errorVolunteerNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'You are not available for emergencies right now.'**
  String get errorVolunteerNotAvailable;

  /// No description provided for @errorEmergencyAlreadyAssigned.
  ///
  /// In en, this message translates to:
  /// **'This emergency has already been handled by someone else.'**
  String get errorEmergencyAlreadyAssigned;

  /// No description provided for @errorAssignmentExpired.
  ///
  /// In en, this message translates to:
  /// **'This assignment has expired.'**
  String get errorAssignmentExpired;

  /// No description provided for @errorLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your location is unavailable. Turn on location services and try again.'**
  String get errorLocationUnavailable;

  /// No description provided for @errorRoutingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Route information is unavailable right now.'**
  String get errorRoutingUnavailable;

  /// No description provided for @errorFileUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'The file could not be uploaded. Please try again.'**
  String get errorFileUploadFailed;

  /// No description provided for @errorInternal.
  ///
  /// In en, this message translates to:
  /// **'A server error occurred. Please try again shortly.'**
  String get errorInternal;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to get help quickly when you need it.'**
  String get authLoginSubtitle;

  /// No description provided for @authIdentifierLabel.
  ///
  /// In en, this message translates to:
  /// **'Email or username'**
  String get authIdentifierLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authLoginButton;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'New to MedAID?'**
  String get authNoAccount;

  /// No description provided for @authCreateAccountLink.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get authCreateAccountLink;

  /// No description provided for @authStaffNote.
  ///
  /// In en, this message translates to:
  /// **'Volunteers and admins: use the account created for you.'**
  String get authStaffNote;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'It takes less than a minute.'**
  String get authRegisterSubtitle;

  /// No description provided for @authNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authNameLabel;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authUsernameLabel;

  /// No description provided for @authPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number (optional)'**
  String get authPhoneLabel;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authRegisterButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authRegisterButton;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccount;

  /// No description provided for @authLoginLink.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authLoginLink;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get authLogout;

  /// No description provided for @authLogoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get authLogoutConfirmTitle;

  /// No description provided for @authLogoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need to log in again to use MedAID.'**
  String get authLogoutConfirmMessage;

  /// No description provided for @authChangePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get authChangePasswordTitle;

  /// No description provided for @authChangePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For your security, choose a new password before continuing.'**
  String get authChangePasswordSubtitle;

  /// No description provided for @authCurrentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get authCurrentPasswordLabel;

  /// No description provided for @authNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPasswordLabel;

  /// No description provided for @authChangePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get authChangePasswordButton;

  /// No description provided for @authPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Your password has been updated.'**
  String get authPasswordChanged;

  /// No description provided for @authAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Welcome to MedAID!'**
  String get authAccountCreated;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get validationRequired;

  /// No description provided for @validationEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get validationEmail;

  /// No description provided for @validationUsername.
  ///
  /// In en, this message translates to:
  /// **'Use 3–30 letters, numbers, dots or underscores.'**
  String get validationUsername;

  /// No description provided for @validationPassword.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters, including letters and numbers.'**
  String get validationPassword;

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get validationPasswordMismatch;

  /// No description provided for @validationPasswordSame.
  ///
  /// In en, this message translates to:
  /// **'The new password must be different.'**
  String get validationPasswordSame;

  /// No description provided for @validationPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number.'**
  String get validationPhone;

  /// No description provided for @validationName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name.'**
  String get validationName;

  /// No description provided for @errorPasswordChangeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please set a new password to continue.'**
  String get errorPasswordChangeRequired;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String homeGreeting(String name);

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get commonAllow;

  /// No description provided for @commonOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get commonOpenSettings;

  /// No description provided for @commonUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get commonUpload;

  /// No description provided for @commonReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get commonReplace;

  /// No description provided for @authAccountExists.
  ///
  /// In en, this message translates to:
  /// **'This email or username is already in use.'**
  String get authAccountExists;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navFacilities.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get navFacilities;

  /// No description provided for @navEmergencies.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navEmergencies;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @commonCallEmergency.
  ///
  /// In en, this message translates to:
  /// **'Call 112'**
  String get commonCallEmergency;

  /// No description provided for @commonNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get commonNotSet;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help is one button away.'**
  String get homeSubtitle;

  /// No description provided for @sosLabel.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sosLabel;

  /// No description provided for @sosHoldHint.
  ///
  /// In en, this message translates to:
  /// **'Hold for help'**
  String get sosHoldHint;

  /// No description provided for @sosSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Send an emergency alert'**
  String get sosSemanticLabel;

  /// No description provided for @sosCardTitle.
  ///
  /// In en, this message translates to:
  /// **'In an emergency?'**
  String get sosCardTitle;

  /// No description provided for @sosCardBody.
  ///
  /// In en, this message translates to:
  /// **'Press and hold the button. We will share your location with the nearest volunteer.'**
  String get sosCardBody;

  /// No description provided for @homeActiveAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'You have an active alert'**
  String get homeActiveAlertTitle;

  /// No description provided for @homeActiveAlertAction.
  ///
  /// In en, this message translates to:
  /// **'View status'**
  String get homeActiveAlertAction;

  /// No description provided for @homeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'What do you need?'**
  String get homeQuickActions;

  /// No description provided for @homeSymptomsTitle.
  ///
  /// In en, this message translates to:
  /// **'Check symptoms'**
  String get homeSymptomsTitle;

  /// No description provided for @homeSymptomsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get general guidance'**
  String get homeSymptomsSubtitle;

  /// No description provided for @homeFacilitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Hospitals & camps'**
  String get homeFacilitiesTitle;

  /// No description provided for @homeFacilitiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find help near you'**
  String get homeFacilitiesSubtitle;

  /// No description provided for @homeHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'My alerts'**
  String get homeHistoryTitle;

  /// No description provided for @homeHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Status and history'**
  String get homeHistorySubtitle;

  /// No description provided for @sosSendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Sending your alert'**
  String get sosSendingTitle;

  /// No description provided for @sosStepLocating.
  ///
  /// In en, this message translates to:
  /// **'Getting your location…'**
  String get sosStepLocating;

  /// No description provided for @sosStepSending.
  ///
  /// In en, this message translates to:
  /// **'Alerting volunteers…'**
  String get sosStepSending;

  /// No description provided for @sosFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Alert not sent'**
  String get sosFailedTitle;

  /// No description provided for @sosFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not send your alert. Try again, or call 112 now.'**
  String get sosFailedMessage;

  /// No description provided for @sosNoLocationWarning.
  ///
  /// In en, this message translates to:
  /// **'We could not get your location, so the control room has been alerted. If you can, call 112.'**
  String get sosNoLocationWarning;

  /// No description provided for @emergencyStatusCreated.
  ///
  /// In en, this message translates to:
  /// **'Alert sent'**
  String get emergencyStatusCreated;

  /// No description provided for @emergencyStatusAssigning.
  ///
  /// In en, this message translates to:
  /// **'Finding a volunteer'**
  String get emergencyStatusAssigning;

  /// No description provided for @emergencyStatusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Contacting a volunteer'**
  String get emergencyStatusAssigned;

  /// No description provided for @emergencyStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Help is on the way'**
  String get emergencyStatusAccepted;

  /// No description provided for @emergencyStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'Responder with you'**
  String get emergencyStatusInProgress;

  /// No description provided for @emergencyStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get emergencyStatusResolved;

  /// No description provided for @emergencyStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get emergencyStatusCancelled;

  /// No description provided for @emergencyStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get emergencyStatusExpired;

  /// No description provided for @emergencyStatusUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a volunteer'**
  String get emergencyStatusUnassigned;

  /// No description provided for @emergencyReasonNoLocation.
  ///
  /// In en, this message translates to:
  /// **'No location was available'**
  String get emergencyReasonNoLocation;

  /// No description provided for @emergencyReasonNoVolunteer.
  ///
  /// In en, this message translates to:
  /// **'No volunteer available nearby'**
  String get emergencyReasonNoVolunteer;

  /// No description provided for @emergencyReasonCandidatesBusy.
  ///
  /// In en, this message translates to:
  /// **'Nearby volunteers were busy'**
  String get emergencyReasonCandidatesBusy;

  /// No description provided for @emergencyReasonVolunteerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The volunteer became unavailable'**
  String get emergencyReasonVolunteerUnavailable;

  /// No description provided for @emergencyReasonTimeout.
  ///
  /// In en, this message translates to:
  /// **'No answer in time'**
  String get emergencyReasonTimeout;

  /// No description provided for @emergencyReasonDeclined.
  ///
  /// In en, this message translates to:
  /// **'The volunteer could not come'**
  String get emergencyReasonDeclined;

  /// No description provided for @emergencyReasonAdminReassigned.
  ///
  /// In en, this message translates to:
  /// **'Reassigned by the control room'**
  String get emergencyReasonAdminReassigned;

  /// No description provided for @emergencyMessageSearching.
  ///
  /// In en, this message translates to:
  /// **'We are finding the nearest available volunteer. Stay where you are if it is safe.'**
  String get emergencyMessageSearching;

  /// No description provided for @emergencyMessageAccepted.
  ///
  /// In en, this message translates to:
  /// **'{name} accepted your alert and is coming to you.'**
  String emergencyMessageAccepted(String name);

  /// No description provided for @emergencyMessageAcceptedNoName.
  ///
  /// In en, this message translates to:
  /// **'A volunteer accepted your alert and is coming to you.'**
  String get emergencyMessageAcceptedNoName;

  /// No description provided for @emergencyMessageInProgress.
  ///
  /// In en, this message translates to:
  /// **'Your responder has reached you.'**
  String get emergencyMessageInProgress;

  /// No description provided for @emergencyMessageUnassigned.
  ///
  /// In en, this message translates to:
  /// **'No volunteer is free right now. The control room has been alerted and we keep trying. If you can, call 112.'**
  String get emergencyMessageUnassigned;

  /// No description provided for @emergencyMessageResolved.
  ///
  /// In en, this message translates to:
  /// **'This alert has been resolved. We hope you are feeling better.'**
  String get emergencyMessageResolved;

  /// No description provided for @emergencyMessageCancelled.
  ///
  /// In en, this message translates to:
  /// **'This alert was cancelled.'**
  String get emergencyMessageCancelled;

  /// No description provided for @emergencyEta.
  ///
  /// In en, this message translates to:
  /// **'About {minutes} min away'**
  String emergencyEta(int minutes);

  /// No description provided for @emergencyDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency alert'**
  String get emergencyDetailTitle;

  /// No description provided for @emergencyTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get emergencyTimelineTitle;

  /// No description provided for @emergencyYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your shared location'**
  String get emergencyYourLocation;

  /// No description provided for @emergencyNoLocation.
  ///
  /// In en, this message translates to:
  /// **'Location not shared'**
  String get emergencyNoLocation;

  /// No description provided for @emergencyCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel alert'**
  String get emergencyCancelAction;

  /// No description provided for @emergencyCancelConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this alert?'**
  String get emergencyCancelConfirmTitle;

  /// No description provided for @emergencyCancelConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Only cancel if you no longer need help. A volunteer on the way will be told to stop.'**
  String get emergencyCancelConfirmMessage;

  /// No description provided for @emergencyKeepAlert.
  ///
  /// In en, this message translates to:
  /// **'Keep alert'**
  String get emergencyKeepAlert;

  /// No description provided for @emergencyCancelled.
  ///
  /// In en, this message translates to:
  /// **'Your alert was cancelled.'**
  String get emergencyCancelled;

  /// No description provided for @emergencyHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No alerts yet'**
  String get emergencyHistoryEmptyTitle;

  /// No description provided for @emergencyHistoryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Alerts you send will appear here.'**
  String get emergencyHistoryEmptyMessage;

  /// No description provided for @emergencyLiveUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates automatically'**
  String get emergencyLiveUpdates;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String timeHoursAgo(int count);

  /// No description provided for @distanceMeters.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String distanceMeters(String meters);

  /// No description provided for @distanceKilometers.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String distanceKilometers(String km);

  /// No description provided for @symptomsTitle.
  ///
  /// In en, this message translates to:
  /// **'Symptom checker'**
  String get symptomsTitle;

  /// No description provided for @symptomsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select everything you are experiencing.'**
  String get symptomsSubtitle;

  /// No description provided for @symptomsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search symptoms'**
  String get symptomsSearchHint;

  /// No description provided for @symptomsAboutYou.
  ///
  /// In en, this message translates to:
  /// **'About the person'**
  String get symptomsAboutYou;

  /// No description provided for @symptomsAgeYoungChild.
  ///
  /// In en, this message translates to:
  /// **'Under 5'**
  String get symptomsAgeYoungChild;

  /// No description provided for @symptomsAgeChild.
  ///
  /// In en, this message translates to:
  /// **'5–17 years'**
  String get symptomsAgeChild;

  /// No description provided for @symptomsAgeAdult.
  ///
  /// In en, this message translates to:
  /// **'18–64 years'**
  String get symptomsAgeAdult;

  /// No description provided for @symptomsAgeOlder.
  ///
  /// In en, this message translates to:
  /// **'65 or older'**
  String get symptomsAgeOlder;

  /// No description provided for @symptomsPregnant.
  ///
  /// In en, this message translates to:
  /// **'Pregnant'**
  String get symptomsPregnant;

  /// No description provided for @symptomsDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'How long?'**
  String get symptomsDurationLabel;

  /// No description provided for @symptomsDurationToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get symptomsDurationToday;

  /// No description provided for @symptomsDurationFewDays.
  ///
  /// In en, this message translates to:
  /// **'1–2 days'**
  String get symptomsDurationFewDays;

  /// No description provided for @symptomsDurationLonger.
  ///
  /// In en, this message translates to:
  /// **'3+ days'**
  String get symptomsDurationLonger;

  /// No description provided for @symptomsCheckButton.
  ///
  /// In en, this message translates to:
  /// **'Get guidance'**
  String get symptomsCheckButton;

  /// No description provided for @symptomsSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String symptomsSelectedCount(int count);

  /// No description provided for @symptomsEmergencyShortcut.
  ///
  /// In en, this message translates to:
  /// **'Severe symptoms? Don\'t wait — use SOS.'**
  String get symptomsEmergencyShortcut;

  /// No description provided for @symptomsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No symptoms match your search.'**
  String get symptomsNoMatch;

  /// No description provided for @symptomsResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Your guidance'**
  String get symptomsResultTitle;

  /// No description provided for @symptomsWhatToDo.
  ///
  /// In en, this message translates to:
  /// **'What to do now'**
  String get symptomsWhatToDo;

  /// No description provided for @symptomsWarningSignsTitle.
  ///
  /// In en, this message translates to:
  /// **'Use SOS right away if you notice'**
  String get symptomsWarningSignsTitle;

  /// No description provided for @symptomsSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Symptoms you selected'**
  String get symptomsSelectedTitle;

  /// No description provided for @symptomsFindFacility.
  ///
  /// In en, this message translates to:
  /// **'Find nearest hospital or camp'**
  String get symptomsFindFacility;

  /// No description provided for @symptomsUseSos.
  ///
  /// In en, this message translates to:
  /// **'Send SOS alert'**
  String get symptomsUseSos;

  /// No description provided for @symptomsStartOver.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get symptomsStartOver;

  /// No description provided for @triageEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get triageEmergency;

  /// No description provided for @triageUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get triageUrgent;

  /// No description provided for @triageRoutine.
  ///
  /// In en, this message translates to:
  /// **'Not urgent'**
  String get triageRoutine;

  /// No description provided for @facilitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby help'**
  String get facilitiesTitle;

  /// No description provided for @facilitiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hospitals and medical camps near you'**
  String get facilitiesSubtitle;

  /// No description provided for @facilitiesFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get facilitiesFilterAll;

  /// No description provided for @facilitiesFilterHospitals.
  ///
  /// In en, this message translates to:
  /// **'Hospitals'**
  String get facilitiesFilterHospitals;

  /// No description provided for @facilitiesFilterCamps.
  ///
  /// In en, this message translates to:
  /// **'Medical camps'**
  String get facilitiesFilterCamps;

  /// No description provided for @facilitiesViewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get facilitiesViewList;

  /// No description provided for @facilitiesViewMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get facilitiesViewMap;

  /// No description provided for @facilityTypeHospital.
  ///
  /// In en, this message translates to:
  /// **'Hospital'**
  String get facilityTypeHospital;

  /// No description provided for @facilityTypeCamp.
  ///
  /// In en, this message translates to:
  /// **'Medical camp'**
  String get facilityTypeCamp;

  /// No description provided for @facilityEmergencyDept.
  ///
  /// In en, this message translates to:
  /// **'Emergency care'**
  String get facilityEmergencyDept;

  /// No description provided for @facilityOpenUntil.
  ///
  /// In en, this message translates to:
  /// **'Open until {time}'**
  String facilityOpenUntil(String time);

  /// No description provided for @facilitiesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing found nearby'**
  String get facilitiesEmptyTitle;

  /// No description provided for @facilitiesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Try another filter, or use SOS if you need urgent help.'**
  String get facilitiesEmptyMessage;

  /// No description provided for @facilityServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get facilityServicesTitle;

  /// No description provided for @facilityAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get facilityAddressTitle;

  /// No description provided for @facilityContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get facilityContactTitle;

  /// No description provided for @facilityCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get facilityCall;

  /// No description provided for @facilityDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get facilityDirections;

  /// No description provided for @facilityValidityTitle.
  ///
  /// In en, this message translates to:
  /// **'Open hours'**
  String get facilityValidityTitle;

  /// No description provided for @facilityAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get facilityAbout;

  /// No description provided for @locationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow location access'**
  String get locationPermissionTitle;

  /// No description provided for @locationPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'MedAID uses your location to show help nearby and to guide volunteers to you in an emergency.'**
  String get locationPermissionMessage;

  /// No description provided for @locationServicesOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on location'**
  String get locationServicesOffTitle;

  /// No description provided for @locationServicesOffMessage.
  ///
  /// In en, this message translates to:
  /// **'Location services are off on this phone.'**
  String get locationServicesOffMessage;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profilePersonalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get profilePersonalDetails;

  /// No description provided for @profileMedicalInfo.
  ///
  /// In en, this message translates to:
  /// **'Medical information'**
  String get profileMedicalInfo;

  /// No description provided for @profileMedicalInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shared with responders only if you allow it'**
  String get profileMedicalInfoSubtitle;

  /// No description provided for @profileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get profileEditTitle;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Your changes were saved.'**
  String get profileSaved;

  /// No description provided for @profileChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get profileChangePassword;

  /// No description provided for @medicalDob.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get medicalDob;

  /// No description provided for @medicalGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get medicalGender;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @genderPreferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get genderPreferNotToSay;

  /// No description provided for @medicalBloodGroup.
  ///
  /// In en, this message translates to:
  /// **'Blood group'**
  String get medicalBloodGroup;

  /// No description provided for @bloodGroupUnknown.
  ///
  /// In en, this message translates to:
  /// **'Don\'t know'**
  String get bloodGroupUnknown;

  /// No description provided for @medicalAllergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get medicalAllergies;

  /// No description provided for @medicalConditions.
  ///
  /// In en, this message translates to:
  /// **'Existing medical conditions'**
  String get medicalConditions;

  /// No description provided for @medicalEmergencyContactName.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact name'**
  String get medicalEmergencyContactName;

  /// No description provided for @medicalEmergencyContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact phone'**
  String get medicalEmergencyContactPhone;

  /// No description provided for @medicalShareConsent.
  ///
  /// In en, this message translates to:
  /// **'Share this information with the volunteer who responds to my alert'**
  String get medicalShareConsent;

  /// No description provided for @medicalShareConsentHelp.
  ///
  /// In en, this message translates to:
  /// **'Only the assigned volunteer and administrators can see it, and only during an alert.'**
  String get medicalShareConsentHelp;

  /// No description provided for @medicalOptionalNote.
  ///
  /// In en, this message translates to:
  /// **'All fields are optional.'**
  String get medicalOptionalNote;

  /// No description provided for @errorFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This file is larger than 5 MB. Please choose a smaller file.'**
  String get errorFileTooLarge;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @verificationNotSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Not submitted'**
  String get verificationNotSubmitted;

  /// No description provided for @verificationPending.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get verificationPending;

  /// No description provided for @verificationApproved.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verificationApproved;

  /// No description provided for @verificationRejected.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get verificationRejected;

  /// No description provided for @volunteerStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get volunteerStatusActive;

  /// No description provided for @volunteerStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get volunteerStatusOffline;

  /// No description provided for @volunteerStatusBusy.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get volunteerStatusBusy;

  /// No description provided for @documentTypeIdProof.
  ///
  /// In en, this message translates to:
  /// **'ID proof'**
  String get documentTypeIdProof;

  /// No description provided for @documentTypeFirstAid.
  ///
  /// In en, this message translates to:
  /// **'First-aid certificate'**
  String get documentTypeFirstAid;

  /// No description provided for @documentTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other document'**
  String get documentTypeOther;

  /// No description provided for @documentStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get documentStatusPending;

  /// No description provided for @documentStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get documentStatusApproved;

  /// No description provided for @documentStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get documentStatusRejected;

  /// No description provided for @assignmentPending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting your response'**
  String get assignmentPending;

  /// No description provided for @assignmentAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get assignmentAccepted;

  /// No description provided for @assignmentDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get assignmentDeclined;

  /// No description provided for @assignmentExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get assignmentExpired;

  /// No description provided for @assignmentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get assignmentCancelled;

  /// No description provided for @assignmentCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get assignmentCompleted;

  /// No description provided for @volunteerDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Thank you for helping keep people safe.'**
  String get volunteerDashboardSubtitle;

  /// No description provided for @volunteerOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish setting up'**
  String get volunteerOnboardingTitle;

  /// No description provided for @volunteerOnboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete these steps to start receiving emergencies.'**
  String get volunteerOnboardingSubtitle;

  /// No description provided for @volunteerStepProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get volunteerStepProfile;

  /// No description provided for @volunteerStepDocuments.
  ///
  /// In en, this message translates to:
  /// **'Upload verification documents'**
  String get volunteerStepDocuments;

  /// No description provided for @volunteerStepVerification.
  ///
  /// In en, this message translates to:
  /// **'Admin approval'**
  String get volunteerStepVerification;

  /// No description provided for @volunteerAvailabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get volunteerAvailabilityTitle;

  /// No description provided for @volunteerAvailabilityActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'You will receive nearby emergencies.'**
  String get volunteerAvailabilityActiveMessage;

  /// No description provided for @volunteerAvailabilityOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'Go active to receive emergencies.'**
  String get volunteerAvailabilityOfflineMessage;

  /// No description provided for @volunteerAvailabilityBusyMessage.
  ///
  /// In en, this message translates to:
  /// **'Resolve your current emergency to receive new ones.'**
  String get volunteerAvailabilityBusyMessage;

  /// No description provided for @volunteerAvailabilitySwitch.
  ///
  /// In en, this message translates to:
  /// **'Available for emergencies'**
  String get volunteerAvailabilitySwitch;

  /// No description provided for @volunteerCurrentAssignment.
  ///
  /// In en, this message translates to:
  /// **'Current emergency'**
  String get volunteerCurrentAssignment;

  /// No description provided for @volunteerNoAssignmentTitle.
  ///
  /// In en, this message translates to:
  /// **'No emergencies right now'**
  String get volunteerNoAssignmentTitle;

  /// No description provided for @volunteerNoAssignmentMessage.
  ///
  /// In en, this message translates to:
  /// **'Stay active. New emergencies near you will appear here.'**
  String get volunteerNoAssignmentMessage;

  /// No description provided for @volunteerRespondWithin.
  ///
  /// In en, this message translates to:
  /// **'Respond within {time}'**
  String volunteerRespondWithin(String time);

  /// No description provided for @volunteerEmergenciesTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergencies'**
  String get volunteerEmergenciesTitle;

  /// No description provided for @volunteerActiveTab.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get volunteerActiveTab;

  /// No description provided for @volunteerHistoryTab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get volunteerHistoryTab;

  /// No description provided for @volunteerHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Emergencies you respond to will appear here.'**
  String get volunteerHistoryEmpty;

  /// No description provided for @volunteerEmergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get volunteerEmergencyTitle;

  /// No description provided for @volunteerReporterTitle.
  ///
  /// In en, this message translates to:
  /// **'Person in need'**
  String get volunteerReporterTitle;

  /// No description provided for @volunteerCallReporter.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get volunteerCallReporter;

  /// No description provided for @volunteerMedicalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared medical information'**
  String get volunteerMedicalInfoTitle;

  /// No description provided for @volunteerNoMedicalInfo.
  ///
  /// In en, this message translates to:
  /// **'No medical information shared.'**
  String get volunteerNoMedicalInfo;

  /// No description provided for @volunteerLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency location'**
  String get volunteerLocationTitle;

  /// No description provided for @volunteerNoLocation.
  ///
  /// In en, this message translates to:
  /// **'The person could not share a location. Call them or contact the control room.'**
  String get volunteerNoLocation;

  /// No description provided for @volunteerAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept emergency'**
  String get volunteerAccept;

  /// No description provided for @volunteerDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get volunteerDecline;

  /// No description provided for @volunteerDeclineConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline this emergency?'**
  String get volunteerDeclineConfirmTitle;

  /// No description provided for @volunteerDeclineConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'It will be sent to the next available volunteer.'**
  String get volunteerDeclineConfirmMessage;

  /// No description provided for @volunteerStartAssistance.
  ///
  /// In en, this message translates to:
  /// **'I have arrived'**
  String get volunteerStartAssistance;

  /// No description provided for @volunteerResolve.
  ///
  /// In en, this message translates to:
  /// **'Mark as resolved'**
  String get volunteerResolve;

  /// No description provided for @volunteerResolveTitle.
  ///
  /// In en, this message translates to:
  /// **'Resolve emergency'**
  String get volunteerResolveTitle;

  /// No description provided for @volunteerResolveNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'What help was given?'**
  String get volunteerResolveNoteLabel;

  /// No description provided for @volunteerResolveNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. First aid given, escorted to the medical camp'**
  String get volunteerResolveNoteHint;

  /// No description provided for @volunteerResolved.
  ///
  /// In en, this message translates to:
  /// **'Emergency resolved. You are active again.'**
  String get volunteerResolved;

  /// No description provided for @volunteerAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted. The person has been told help is coming.'**
  String get volunteerAccepted;

  /// No description provided for @volunteerExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'This assignment expired and was passed to another volunteer.'**
  String get volunteerExpiredMessage;

  /// No description provided for @volunteerClosedMessage.
  ///
  /// In en, this message translates to:
  /// **'This emergency is closed.'**
  String get volunteerClosedMessage;

  /// No description provided for @volunteerDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get volunteerDirections;

  /// No description provided for @volunteerRouteEta.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min · {distance}'**
  String volunteerRouteEta(int minutes, String distance);

  /// No description provided for @volunteerRouteEstimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated from straight-line distance. The walking route may be longer.'**
  String get volunteerRouteEstimated;

  /// No description provided for @volunteerRouteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Route unavailable right now. Use Directions to navigate.'**
  String get volunteerRouteUnavailable;

  /// No description provided for @trackingNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'MedAID is sharing your location'**
  String get trackingNotificationTitle;

  /// No description provided for @trackingNotificationText.
  ///
  /// In en, this message translates to:
  /// **'Used to send you nearby emergencies. Go offline to stop.'**
  String get trackingNotificationText;

  /// No description provided for @trackingStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting live location…'**
  String get trackingStarting;

  /// No description provided for @trackingActive.
  ///
  /// In en, this message translates to:
  /// **'Sharing live location · {time}'**
  String trackingActive(String time);

  /// No description provided for @trackingOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Location sharing is off'**
  String get trackingOffTitle;

  /// No description provided for @trackingPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Allow location access, or you will stop receiving nearby emergencies within a few minutes.'**
  String get trackingPermissionMessage;

  /// No description provided for @trackingServicesOffMessage.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services, or you will stop receiving nearby emergencies within a few minutes.'**
  String get trackingServicesOffMessage;

  /// No description provided for @volunteerResolutionTitle.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get volunteerResolutionTitle;

  /// No description provided for @profileCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Your details'**
  String get profileCompleteTitle;

  /// No description provided for @profileCompleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Admins use these details to verify you.'**
  String get profileCompleteSubtitle;

  /// No description provided for @volunteerAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get volunteerAddress;

  /// No description provided for @volunteerCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get volunteerCity;

  /// No description provided for @volunteerPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get volunteerPhone;

  /// No description provided for @volunteerSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills (comma separated)'**
  String get volunteerSkills;

  /// No description provided for @volunteerLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages you speak (comma separated)'**
  String get volunteerLanguages;

  /// No description provided for @documentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification documents'**
  String get documentsTitle;

  /// No description provided for @documentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload a clear photo or PDF of each document. Maximum 5 MB.'**
  String get documentsSubtitle;

  /// No description provided for @documentUploaded.
  ///
  /// In en, this message translates to:
  /// **'Document uploaded.'**
  String get documentUploaded;

  /// No description provided for @documentsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Documents submitted for review.'**
  String get documentsSubmitted;

  /// No description provided for @verificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verificationTitle;

  /// No description provided for @verificationPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'An administrator is reviewing your documents. You will be notified when it\'s done.'**
  String get verificationPendingMessage;

  /// No description provided for @verificationApprovedMessage.
  ///
  /// In en, this message translates to:
  /// **'You are verified. Go active from the dashboard to start receiving emergencies.'**
  String get verificationApprovedMessage;

  /// No description provided for @verificationRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your verification was not approved. Please update your documents.'**
  String get verificationRejectedMessage;

  /// No description provided for @verificationNotSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile and upload the required documents.'**
  String get verificationNotSubmittedMessage;

  /// No description provided for @verificationReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get verificationReasonLabel;

  /// No description provided for @verificationUpdateDocuments.
  ///
  /// In en, this message translates to:
  /// **'Update documents'**
  String get verificationUpdateDocuments;

  /// No description provided for @volunteerProfileDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get volunteerProfileDocuments;

  /// No description provided for @navVolunteers.
  ///
  /// In en, this message translates to:
  /// **'Volunteers'**
  String get navVolunteers;

  /// No description provided for @navCamps.
  ///
  /// In en, this message translates to:
  /// **'Camps'**
  String get navCamps;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Control room'**
  String get adminDashboardTitle;

  /// No description provided for @adminDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live overview of emergencies and volunteers'**
  String get adminDashboardSubtitle;

  /// No description provided for @adminStatOpen.
  ///
  /// In en, this message translates to:
  /// **'Open emergencies'**
  String get adminStatOpen;

  /// No description provided for @adminStatUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a volunteer'**
  String get adminStatUnassigned;

  /// No description provided for @adminStatAwaiting.
  ///
  /// In en, this message translates to:
  /// **'Awaiting acceptance'**
  String get adminStatAwaiting;

  /// No description provided for @adminStatInProgress.
  ///
  /// In en, this message translates to:
  /// **'Help on the way'**
  String get adminStatInProgress;

  /// No description provided for @adminStatToday.
  ///
  /// In en, this message translates to:
  /// **'Alerts today'**
  String get adminStatToday;

  /// No description provided for @adminStatPendingVerification.
  ///
  /// In en, this message translates to:
  /// **'Pending verifications'**
  String get adminStatPendingVerification;

  /// No description provided for @adminStatActiveVolunteers.
  ///
  /// In en, this message translates to:
  /// **'Active volunteers'**
  String get adminStatActiveVolunteers;

  /// No description provided for @adminStatBusyVolunteers.
  ///
  /// In en, this message translates to:
  /// **'Busy volunteers'**
  String get adminStatBusyVolunteers;

  /// No description provided for @adminStatActiveCamps.
  ///
  /// In en, this message translates to:
  /// **'Camps open now'**
  String get adminStatActiveCamps;

  /// No description provided for @adminRecentOpen.
  ///
  /// In en, this message translates to:
  /// **'Open emergencies'**
  String get adminRecentOpen;

  /// No description provided for @adminNoOpenEmergencies.
  ///
  /// In en, this message translates to:
  /// **'No open emergencies right now.'**
  String get adminNoOpenEmergencies;

  /// No description provided for @adminFilterOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get adminFilterOpen;

  /// No description provided for @adminFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get adminFilterAll;

  /// No description provided for @adminFilterUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get adminFilterUnassigned;

  /// No description provided for @adminFilterResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get adminFilterResolved;

  /// No description provided for @adminSearchAlert.
  ///
  /// In en, this message translates to:
  /// **'Search alert number'**
  String get adminSearchAlert;

  /// No description provided for @adminEmergenciesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No emergencies match this filter.'**
  String get adminEmergenciesEmpty;

  /// No description provided for @adminReporter.
  ///
  /// In en, this message translates to:
  /// **'Reported by'**
  String get adminReporter;

  /// No description provided for @adminAssignedVolunteer.
  ///
  /// In en, this message translates to:
  /// **'Assigned volunteer'**
  String get adminAssignedVolunteer;

  /// No description provided for @adminNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'No volunteer assigned'**
  String get adminNotAssigned;

  /// No description provided for @adminAttempts.
  ///
  /// In en, this message translates to:
  /// **'Attempts: {count}'**
  String adminAttempts(int count);

  /// No description provided for @adminAssignmentHistory.
  ///
  /// In en, this message translates to:
  /// **'Assignment history'**
  String get adminAssignmentHistory;

  /// No description provided for @adminNoAssignments.
  ///
  /// In en, this message translates to:
  /// **'No dispatch attempts yet.'**
  String get adminNoAssignments;

  /// No description provided for @adminReassign.
  ///
  /// In en, this message translates to:
  /// **'Find another volunteer'**
  String get adminReassign;

  /// No description provided for @adminReassignTo.
  ///
  /// In en, this message translates to:
  /// **'Assign to a volunteer'**
  String get adminReassignTo;

  /// No description provided for @adminReassignConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reassign this emergency?'**
  String get adminReassignConfirmTitle;

  /// No description provided for @adminReassignConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'The current volunteer will be released and the emergency dispatched again.'**
  String get adminReassignConfirmMessage;

  /// No description provided for @adminReassigned.
  ///
  /// In en, this message translates to:
  /// **'Emergency sent for reassignment.'**
  String get adminReassigned;

  /// No description provided for @adminResolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get adminResolve;

  /// No description provided for @adminCancelEmergency.
  ///
  /// In en, this message translates to:
  /// **'Cancel emergency'**
  String get adminCancelEmergency;

  /// No description provided for @adminCloseNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (required)'**
  String get adminCloseNoteLabel;

  /// No description provided for @adminClosed.
  ///
  /// In en, this message translates to:
  /// **'Emergency closed.'**
  String get adminClosed;

  /// No description provided for @adminPickVolunteer.
  ///
  /// In en, this message translates to:
  /// **'Choose a volunteer'**
  String get adminPickVolunteer;

  /// No description provided for @adminNoEligibleVolunteers.
  ///
  /// In en, this message translates to:
  /// **'No active, verified volunteers are available.'**
  String get adminNoEligibleVolunteers;

  /// No description provided for @adminVolunteersTitle.
  ///
  /// In en, this message translates to:
  /// **'Volunteers'**
  String get adminVolunteersTitle;

  /// No description provided for @adminVolunteersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No volunteers match this filter.'**
  String get adminVolunteersEmpty;

  /// No description provided for @adminSearchVolunteers.
  ///
  /// In en, this message translates to:
  /// **'Search by name, email or username'**
  String get adminSearchVolunteers;

  /// No description provided for @adminFilterPendingVerification.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get adminFilterPendingVerification;

  /// No description provided for @adminCreateVolunteer.
  ///
  /// In en, this message translates to:
  /// **'Add volunteer'**
  String get adminCreateVolunteer;

  /// No description provided for @adminCreateVolunteerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The volunteer signs in with a temporary password and must change it.'**
  String get adminCreateVolunteerSubtitle;

  /// No description provided for @adminVolunteerCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Volunteer created'**
  String get adminVolunteerCreatedTitle;

  /// No description provided for @adminTemporaryPasswordMessage.
  ///
  /// In en, this message translates to:
  /// **'Share this temporary password with {name} in person. It will not be shown again.'**
  String adminTemporaryPasswordMessage(String name);

  /// No description provided for @adminCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get adminCopy;

  /// No description provided for @adminCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard.'**
  String get adminCopied;

  /// No description provided for @adminVolunteerDetails.
  ///
  /// In en, this message translates to:
  /// **'Volunteer'**
  String get adminVolunteerDetails;

  /// No description provided for @adminProfileSection.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get adminProfileSection;

  /// No description provided for @adminDocumentsSection.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get adminDocumentsSection;

  /// No description provided for @adminNoDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents uploaded yet.'**
  String get adminNoDocuments;

  /// No description provided for @adminViewDocument.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get adminViewDocument;

  /// No description provided for @adminApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminApprove;

  /// No description provided for @adminReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adminReject;

  /// No description provided for @adminRejectReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection'**
  String get adminRejectReasonLabel;

  /// No description provided for @adminApproved.
  ///
  /// In en, this message translates to:
  /// **'Volunteer approved.'**
  String get adminApproved;

  /// No description provided for @adminRejected.
  ///
  /// In en, this message translates to:
  /// **'Volunteer rejected.'**
  String get adminRejected;

  /// No description provided for @adminSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend account'**
  String get adminSuspend;

  /// No description provided for @adminReactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate account'**
  String get adminReactivate;

  /// No description provided for @adminSuspendConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspend this account?'**
  String get adminSuspendConfirmTitle;

  /// No description provided for @adminSuspendConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'They will be signed out immediately. Any emergency they hold will be reassigned.'**
  String get adminSuspendConfirmMessage;

  /// No description provided for @adminSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get adminSuspended;

  /// No description provided for @adminAccountUpdated.
  ///
  /// In en, this message translates to:
  /// **'Account updated.'**
  String get adminAccountUpdated;

  /// No description provided for @adminLastLocation.
  ///
  /// In en, this message translates to:
  /// **'Last location update'**
  String get adminLastLocation;

  /// No description provided for @adminTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Volunteer tracking'**
  String get adminTrackingTitle;

  /// No description provided for @adminTrackingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Active and busy volunteers'**
  String get adminTrackingSubtitle;

  /// No description provided for @adminTrackingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No volunteers are sharing a location right now.'**
  String get adminTrackingEmpty;

  /// No description provided for @adminTrackingAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} available'**
  String adminTrackingAvailable(int count);

  /// No description provided for @adminTrackingResponding.
  ///
  /// In en, this message translates to:
  /// **'{count} responding'**
  String adminTrackingResponding(int count);

  /// No description provided for @adminTrackingStale.
  ///
  /// In en, this message translates to:
  /// **'{count} location out of date'**
  String adminTrackingStale(int count);

  /// No description provided for @adminCampsTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical camps'**
  String get adminCampsTitle;

  /// No description provided for @adminCampsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No camps match this filter.'**
  String get adminCampsEmpty;

  /// No description provided for @adminCreateCamp.
  ///
  /// In en, this message translates to:
  /// **'Add camp'**
  String get adminCreateCamp;

  /// No description provided for @adminEditCamp.
  ///
  /// In en, this message translates to:
  /// **'Edit camp'**
  String get adminEditCamp;

  /// No description provided for @adminCampName.
  ///
  /// In en, this message translates to:
  /// **'Camp name'**
  String get adminCampName;

  /// No description provided for @adminCampDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get adminCampDescription;

  /// No description provided for @adminCampAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get adminCampAddress;

  /// No description provided for @adminCampServices.
  ///
  /// In en, this message translates to:
  /// **'Services (comma separated)'**
  String get adminCampServices;

  /// No description provided for @adminCampContactName.
  ///
  /// In en, this message translates to:
  /// **'Contact person'**
  String get adminCampContactName;

  /// No description provided for @adminCampContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Contact phone'**
  String get adminCampContactPhone;

  /// No description provided for @adminCampStart.
  ///
  /// In en, this message translates to:
  /// **'Opens'**
  String get adminCampStart;

  /// No description provided for @adminCampEnd.
  ///
  /// In en, this message translates to:
  /// **'Closes'**
  String get adminCampEnd;

  /// No description provided for @adminCampActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminCampActive;

  /// No description provided for @adminCampLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get adminCampLocation;

  /// No description provided for @adminCampLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to place the camp.'**
  String get adminCampLocationHint;

  /// No description provided for @adminCampUseMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get adminCampUseMyLocation;

  /// No description provided for @adminCampLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose the camp location on the map.'**
  String get adminCampLocationRequired;

  /// No description provided for @adminCampEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'The closing time must be after the opening time.'**
  String get adminCampEndBeforeStart;

  /// No description provided for @adminCampSaved.
  ///
  /// In en, this message translates to:
  /// **'Camp saved.'**
  String get adminCampSaved;

  /// No description provided for @adminCampDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete camp'**
  String get adminCampDelete;

  /// No description provided for @adminCampDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Users will no longer see this camp.'**
  String get adminCampDeleteConfirm;

  /// No description provided for @adminCampDeleted.
  ///
  /// In en, this message translates to:
  /// **'Camp deleted.'**
  String get adminCampDeleted;

  /// No description provided for @campLifecycleActiveNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get campLifecycleActiveNow;

  /// No description provided for @campLifecycleUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get campLifecycleUpcoming;

  /// No description provided for @campLifecycleExpired.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get campLifecycleExpired;

  /// No description provided for @campLifecycleInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get campLifecycleInactive;

  /// No description provided for @adminUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminUsersTitle;

  /// No description provided for @adminUsersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No users match this filter.'**
  String get adminUsersEmpty;

  /// No description provided for @adminSearchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search users'**
  String get adminSearchUsers;

  /// No description provided for @roleUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get roleUser;

  /// No description provided for @roleVolunteer.
  ///
  /// In en, this message translates to:
  /// **'Volunteer'**
  String get roleVolunteer;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @adminReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get adminReportsTitle;

  /// No description provided for @adminReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get adminReportsSubtitle;

  /// No description provided for @adminReportTotal.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get adminReportTotal;

  /// No description provided for @adminReportResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get adminReportResolved;

  /// No description provided for @adminReportCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get adminReportCancelled;

  /// No description provided for @adminReportReassignment.
  ///
  /// In en, this message translates to:
  /// **'Needed reassignment'**
  String get adminReportReassignment;

  /// No description provided for @adminReportAvgAccept.
  ///
  /// In en, this message translates to:
  /// **'Avg. time to accept'**
  String get adminReportAvgAccept;

  /// No description provided for @adminReportAvgResolve.
  ///
  /// In en, this message translates to:
  /// **'Avg. time to resolve'**
  String get adminReportAvgResolve;

  /// No description provided for @adminReportPerDay.
  ///
  /// In en, this message translates to:
  /// **'Alerts per day'**
  String get adminReportPerDay;

  /// No description provided for @adminReportNoData.
  ///
  /// In en, this message translates to:
  /// **'No alerts in this period.'**
  String get adminReportNoData;

  /// No description provided for @adminMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String adminMinutes(int count);

  /// No description provided for @adminSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get adminSettingsTitle;

  /// No description provided for @adminMoreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get adminMoreTitle;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Updates about emergencies and your account will appear here.'**
  String get notificationsEmptyMessage;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationsUnread;

  /// No description provided for @notificationsBellLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications, {count} unread'**
  String notificationsBellLabel(int count);

  /// No description provided for @notificationsBadgeMax.
  ///
  /// In en, this message translates to:
  /// **'99+'**
  String get notificationsBadgeMax;

  /// No description provided for @adminNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Send notice to volunteers'**
  String get adminNoticeTitle;

  /// No description provided for @adminNoticeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reaches every verified volunteer'**
  String get adminNoticeSubtitle;

  /// No description provided for @adminNoticeLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get adminNoticeLabel;

  /// No description provided for @adminNoticeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ghat 4 is closed; use the north entrance.'**
  String get adminNoticeHint;

  /// No description provided for @adminNoticeSend.
  ///
  /// In en, this message translates to:
  /// **'Send notice'**
  String get adminNoticeSend;

  /// No description provided for @adminNoticeSent.
  ///
  /// In en, this message translates to:
  /// **'Notice sent to {count} volunteers.'**
  String adminNoticeSent(int count);

  /// No description provided for @symptomsFirstAidTitle.
  ///
  /// In en, this message translates to:
  /// **'First aid you can give now'**
  String get symptomsFirstAidTitle;

  /// No description provided for @exitConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave MedAID?'**
  String get exitConfirmTitle;

  /// No description provided for @exitConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You can reopen the app any time. Your alerts stay active.'**
  String get exitConfirmMessage;

  /// No description provided for @exitConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get exitConfirmAction;

  /// No description provided for @adminDocumentZoomHint.
  ///
  /// In en, this message translates to:
  /// **'Pinch to zoom, drag to move'**
  String get adminDocumentZoomHint;

  /// No description provided for @adminDocumentLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The document could not be loaded. The link expires after a few minutes — go back and open it again.'**
  String get adminDocumentLoadFailed;

  /// No description provided for @adminDocumentPdfNotice.
  ///
  /// In en, this message translates to:
  /// **'This is a PDF. The app cannot display PDF pages yet.'**
  String get adminDocumentPdfNotice;

  /// No description provided for @adminDocumentOpenExternally.
  ///
  /// In en, this message translates to:
  /// **'Open outside the app'**
  String get adminDocumentOpenExternally;

  /// No description provided for @adminDocumentUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show'**
  String get adminDocumentUnavailableTitle;

  /// No description provided for @adminDocumentUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Open a document from the volunteer\'s documents list.'**
  String get adminDocumentUnavailableMessage;

  /// No description provided for @volunteerAlertNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'New emergency near you'**
  String get volunteerAlertNotificationTitle;

  /// No description provided for @volunteerAlertNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Open MedAID and respond within 2 minutes.'**
  String get volunteerAlertNotificationBody;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
