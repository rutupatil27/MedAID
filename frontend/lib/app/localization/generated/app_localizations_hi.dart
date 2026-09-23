// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'MedAID';

  @override
  String get appTagline => 'बड़े आयोजनों में आपातकालीन स्वास्थ्य सहायता';

  @override
  String get commonLoading => 'लोड हो रहा है…';

  @override
  String get commonRetry => 'फिर से कोशिश करें';

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get commonConfirm => 'पुष्टि करें';

  @override
  String get commonSave => 'सहेजें';

  @override
  String get commonContinue => 'आगे बढ़ें';

  @override
  String get commonClose => 'बंद करें';

  @override
  String get commonBack => 'वापस';

  @override
  String get commonOk => 'ठीक है';

  @override
  String get commonYes => 'हाँ';

  @override
  String get commonNo => 'नहीं';

  @override
  String get commonSubmit => 'जमा करें';

  @override
  String get commonEdit => 'बदलें';

  @override
  String get commonDelete => 'हटाएँ';

  @override
  String get commonSearch => 'खोजें';

  @override
  String get commonViewAll => 'सभी देखें';

  @override
  String get commonDetails => 'विवरण';

  @override
  String get commonRefresh => 'रीफ़्रेश करें';

  @override
  String get commonNotAvailable => 'उपलब्ध नहीं';

  @override
  String get languageTitle => 'भाषा';

  @override
  String get languageSubtitle => 'ऐप के लिए भाषा चुनें';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageMarathi => 'मराठी';

  @override
  String get errorGeneric => 'कुछ गलत हो गया। कृपया फिर से कोशिश करें।';

  @override
  String get errorNetwork => 'इंटरनेट कनेक्शन नहीं है। अपना नेटवर्क जाँचें और फिर से कोशिश करें।';

  @override
  String get errorTimeout => 'सर्वर जवाब देने में बहुत समय ले रहा है। कृपया फिर से कोशिश करें।';

  @override
  String get errorAuthInvalid => 'ईमेल/यूज़रनेम या पासवर्ड गलत है।';

  @override
  String get errorUnauthorized => 'आपका सत्र समाप्त हो गया है। कृपया फिर से लॉग इन करें।';

  @override
  String get errorForbidden => 'आपको यह करने की अनुमति नहीं है।';

  @override
  String get errorAccountSuspended => 'यह खाता निलंबित है। कृपया व्यवस्थापक से संपर्क करें।';

  @override
  String get errorValidation => 'कृपया चिह्नित जानकारी जाँचें।';

  @override
  String get errorNotFound => 'आप जो ढूँढ रहे थे वह नहीं मिला।';

  @override
  String get errorConflict => 'यह कार्य नवीनतम स्थिति से मेल नहीं खाता। कृपया रीफ़्रेश करें।';

  @override
  String get errorRateLimited => 'बहुत अधिक प्रयास। कृपया थोड़ी देर रुककर फिर से कोशिश करें।';

  @override
  String get errorVolunteerNotVerified => 'आपका स्वयंसेवक सत्यापन अभी स्वीकृत नहीं हुआ है।';

  @override
  String get errorVolunteerNotAvailable => 'आप अभी आपात स्थितियों के लिए उपलब्ध नहीं हैं।';

  @override
  String get errorEmergencyAlreadyAssigned =>
      'यह आपात स्थिति पहले ही किसी और द्वारा संभाली जा चुकी है।';

  @override
  String get errorAssignmentExpired => 'यह असाइनमेंट समाप्त हो गया है।';

  @override
  String get errorLocationUnavailable =>
      'आपका स्थान उपलब्ध नहीं है। लोकेशन सेवा चालू करें और फिर से कोशिश करें।';

  @override
  String get errorRoutingUnavailable => 'रास्ते की जानकारी अभी उपलब्ध नहीं है।';

  @override
  String get errorFileUploadFailed => 'फ़ाइल अपलोड नहीं हो सकी। कृपया फिर से कोशिश करें।';

  @override
  String get errorInternal => 'सर्वर में त्रुटि हुई। कृपया थोड़ी देर बाद फिर से कोशिश करें।';

  @override
  String get authLoginTitle => 'फिर से स्वागत है';

  @override
  String get authLoginSubtitle => 'ज़रूरत पड़ने पर जल्दी मदद पाने के लिए लॉग इन करें।';

  @override
  String get authIdentifierLabel => 'ईमेल या यूज़रनेम';

  @override
  String get authPasswordLabel => 'पासवर्ड';

  @override
  String get authLoginButton => 'लॉग इन करें';

  @override
  String get authNoAccount => 'MedAID पर नए हैं?';

  @override
  String get authCreateAccountLink => 'खाता बनाएँ';

  @override
  String get authStaffNote => 'स्वयंसेवक और व्यवस्थापक: आपके लिए बनाए गए खाते का उपयोग करें।';

  @override
  String get authRegisterTitle => 'अपना खाता बनाएँ';

  @override
  String get authRegisterSubtitle => 'इसमें एक मिनट से भी कम समय लगता है।';

  @override
  String get authNameLabel => 'पूरा नाम';

  @override
  String get authEmailLabel => 'ईमेल';

  @override
  String get authUsernameLabel => 'यूज़रनेम';

  @override
  String get authPhoneLabel => 'फ़ोन नंबर (वैकल्पिक)';

  @override
  String get authConfirmPasswordLabel => 'पासवर्ड की पुष्टि करें';

  @override
  String get authRegisterButton => 'खाता बनाएँ';

  @override
  String get authHaveAccount => 'पहले से खाता है?';

  @override
  String get authLoginLink => 'लॉग इन करें';

  @override
  String get authShowPassword => 'पासवर्ड दिखाएँ';

  @override
  String get authHidePassword => 'पासवर्ड छिपाएँ';

  @override
  String get authLogout => 'लॉग आउट करें';

  @override
  String get authLogoutConfirmTitle => 'लॉग आउट करें?';

  @override
  String get authLogoutConfirmMessage =>
      'MedAID का उपयोग करने के लिए आपको फिर से लॉग इन करना होगा।';

  @override
  String get authChangePasswordTitle => 'नया पासवर्ड सेट करें';

  @override
  String get authChangePasswordSubtitle =>
      'आपकी सुरक्षा के लिए, आगे बढ़ने से पहले नया पासवर्ड चुनें।';

  @override
  String get authCurrentPasswordLabel => 'वर्तमान पासवर्ड';

  @override
  String get authNewPasswordLabel => 'नया पासवर्ड';

  @override
  String get authChangePasswordButton => 'पासवर्ड अपडेट करें';

  @override
  String get authPasswordChanged => 'आपका पासवर्ड अपडेट हो गया है।';

  @override
  String get authAccountCreated => 'MedAID में आपका स्वागत है!';

  @override
  String get validationRequired => 'यह फ़ील्ड आवश्यक है।';

  @override
  String get validationEmail => 'मान्य ईमेल पता दर्ज करें।';

  @override
  String get validationUsername => '3–30 अक्षर, अंक, डॉट या अंडरस्कोर का उपयोग करें।';

  @override
  String get validationPassword => 'कम से कम 8 अक्षर रखें, जिनमें अक्षर और अंक दोनों हों।';

  @override
  String get validationPasswordMismatch => 'पासवर्ड मेल नहीं खाते।';

  @override
  String get validationPasswordSame => 'नया पासवर्ड अलग होना चाहिए।';

  @override
  String get validationPhone => 'मान्य फ़ोन नंबर दर्ज करें।';

  @override
  String get validationName => 'अपना पूरा नाम दर्ज करें।';

  @override
  String get errorPasswordChangeRequired => 'आगे बढ़ने के लिए कृपया नया पासवर्ड सेट करें।';

  @override
  String homeGreeting(String name) {
    return 'नमस्ते, $name';
  }

  @override
  String get commonClear => 'साफ़ करें';

  @override
  String get commonAllow => 'अनुमति दें';

  @override
  String get commonOpenSettings => 'सेटिंग्स खोलें';

  @override
  String get commonUpload => 'अपलोड करें';

  @override
  String get commonReplace => 'बदलें';

  @override
  String get authAccountExists => 'यह ईमेल या यूज़रनेम पहले से उपयोग में है।';

  @override
  String get navHome => 'होम';

  @override
  String get navFacilities => 'नज़दीकी';

  @override
  String get navEmergencies => 'अलर्ट';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get commonCallEmergency => '112 पर कॉल करें';

  @override
  String get commonNotSet => 'सेट नहीं';

  @override
  String get homeSubtitle => 'मदद बस एक बटन दूर है।';

  @override
  String get sosLabel => 'SOS';

  @override
  String get sosHoldHint => 'मदद के लिए दबाए रखें';

  @override
  String get sosSemanticLabel => 'आपातकालीन अलर्ट भेजें';

  @override
  String get sosCardTitle => 'आपात स्थिति में हैं?';

  @override
  String get sosCardBody => 'बटन दबाकर रखें। हम आपका स्थान नज़दीकी स्वयंसेवक के साथ साझा करेंगे।';

  @override
  String get homeActiveAlertTitle => 'आपका एक अलर्ट सक्रिय है';

  @override
  String get homeActiveAlertAction => 'स्थिति देखें';

  @override
  String get homeQuickActions => 'आपको क्या चाहिए?';

  @override
  String get homeSymptomsTitle => 'लक्षण जाँचें';

  @override
  String get homeSymptomsSubtitle => 'सामान्य मार्गदर्शन पाएँ';

  @override
  String get homeFacilitiesTitle => 'अस्पताल और कैंप';

  @override
  String get homeFacilitiesSubtitle => 'अपने पास मदद खोजें';

  @override
  String get homeHistoryTitle => 'मेरे अलर्ट';

  @override
  String get homeHistorySubtitle => 'स्थिति और इतिहास';

  @override
  String get sosSendingTitle => 'आपका अलर्ट भेजा जा रहा है';

  @override
  String get sosStepLocating => 'आपका स्थान पता किया जा रहा है…';

  @override
  String get sosStepSending => 'स्वयंसेवकों को सूचित किया जा रहा है…';

  @override
  String get sosFailedTitle => 'अलर्ट नहीं भेजा गया';

  @override
  String get sosFailedMessage =>
      'हम आपका अलर्ट नहीं भेज सके। फिर से कोशिश करें या अभी 112 पर कॉल करें।';

  @override
  String get sosNoLocationWarning =>
      'हमें आपका स्थान नहीं मिला, इसलिए नियंत्रण कक्ष को सूचित किया गया है। हो सके तो 112 पर कॉल करें।';

  @override
  String get emergencyStatusCreated => 'अलर्ट भेजा गया';

  @override
  String get emergencyStatusAssigning => 'स्वयंसेवक खोजा जा रहा है';

  @override
  String get emergencyStatusAssigned => 'स्वयंसेवक से संपर्क हो रहा है';

  @override
  String get emergencyStatusAccepted => 'मदद आ रही है';

  @override
  String get emergencyStatusInProgress => 'सहायक आपके पास है';

  @override
  String get emergencyStatusResolved => 'समाधान हो गया';

  @override
  String get emergencyStatusCancelled => 'रद्द किया गया';

  @override
  String get emergencyStatusExpired => 'बंद';

  @override
  String get emergencyStatusUnassigned => 'स्वयंसेवक की प्रतीक्षा';

  @override
  String get emergencyReasonNoLocation => 'स्थान उपलब्ध नहीं था';

  @override
  String get emergencyReasonNoVolunteer => 'आस-पास कोई स्वयंसेवक उपलब्ध नहीं';

  @override
  String get emergencyReasonCandidatesBusy => 'आस-पास के स्वयंसेवक व्यस्त थे';

  @override
  String get emergencyReasonVolunteerUnavailable => 'स्वयंसेवक अनुपलब्ध हो गया';

  @override
  String get emergencyReasonTimeout => 'समय पर कोई जवाब नहीं';

  @override
  String get emergencyReasonDeclined => 'स्वयंसेवक नहीं आ सका';

  @override
  String get emergencyReasonAdminReassigned => 'नियंत्रण कक्ष द्वारा पुनः सौंपा गया';

  @override
  String get emergencyMessageSearching =>
      'हम सबसे नज़दीकी उपलब्ध स्वयंसेवक खोज रहे हैं। सुरक्षित हो तो वहीं रहें।';

  @override
  String emergencyMessageAccepted(String name) {
    return '$name ने आपका अलर्ट स्वीकार किया है और आपकी ओर आ रहे हैं।';
  }

  @override
  String get emergencyMessageAcceptedNoName =>
      'एक स्वयंसेवक ने आपका अलर्ट स्वीकार किया है और आपकी ओर आ रहे हैं।';

  @override
  String get emergencyMessageInProgress => 'आपका सहायक आपके पास पहुँच गया है।';

  @override
  String get emergencyMessageUnassigned =>
      'अभी कोई स्वयंसेवक उपलब्ध नहीं है। नियंत्रण कक्ष को सूचित कर दिया गया है और हम कोशिश जारी रखे हुए हैं। हो सके तो 112 पर कॉल करें।';

  @override
  String get emergencyMessageResolved =>
      'यह अलर्ट हल हो गया है। आशा है आप अब बेहतर महसूस कर रहे हैं।';

  @override
  String get emergencyMessageCancelled => 'यह अलर्ट रद्द कर दिया गया।';

  @override
  String emergencyEta(int minutes) {
    return 'लगभग $minutes मिनट दूर';
  }

  @override
  String get emergencyDetailTitle => 'आपातकालीन अलर्ट';

  @override
  String get emergencyTimelineTitle => 'घटनाक्रम';

  @override
  String get emergencyYourLocation => 'आपका साझा किया गया स्थान';

  @override
  String get emergencyNoLocation => 'स्थान साझा नहीं हुआ';

  @override
  String get emergencyCancelAction => 'अलर्ट रद्द करें';

  @override
  String get emergencyCancelConfirmTitle => 'यह अलर्ट रद्द करें?';

  @override
  String get emergencyCancelConfirmMessage =>
      'केवल तभी रद्द करें जब आपको अब मदद की ज़रूरत न हो। रास्ते में आ रहे स्वयंसेवक को रुकने के लिए कहा जाएगा।';

  @override
  String get emergencyKeepAlert => 'अलर्ट जारी रखें';

  @override
  String get emergencyCancelled => 'आपका अलर्ट रद्द कर दिया गया।';

  @override
  String get emergencyHistoryEmptyTitle => 'अभी कोई अलर्ट नहीं';

  @override
  String get emergencyHistoryEmptyMessage => 'आपके भेजे गए अलर्ट यहाँ दिखेंगे।';

  @override
  String get emergencyLiveUpdates => 'अपने आप अपडेट होता है';

  @override
  String get timeJustNow => 'अभी-अभी';

  @override
  String timeMinutesAgo(int count) {
    return '$count मिनट पहले';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count घंटे पहले';
  }

  @override
  String distanceMeters(String meters) {
    return '$meters मी';
  }

  @override
  String distanceKilometers(String km) {
    return '$km किमी';
  }

  @override
  String get symptomsTitle => 'लक्षण जाँच';

  @override
  String get symptomsSubtitle => 'जो भी लक्षण हैं, सभी चुनें।';

  @override
  String get symptomsSearchHint => 'लक्षण खोजें';

  @override
  String get symptomsAboutYou => 'व्यक्ति के बारे में';

  @override
  String get symptomsAgeYoungChild => '5 साल से कम';

  @override
  String get symptomsAgeChild => '5–17 वर्ष';

  @override
  String get symptomsAgeAdult => '18–64 वर्ष';

  @override
  String get symptomsAgeOlder => '65 या अधिक';

  @override
  String get symptomsPregnant => 'गर्भवती';

  @override
  String get symptomsDurationLabel => 'कब से?';

  @override
  String get symptomsDurationToday => 'आज से';

  @override
  String get symptomsDurationFewDays => '1–2 दिन';

  @override
  String get symptomsDurationLonger => '3+ दिन';

  @override
  String get symptomsCheckButton => 'मार्गदर्शन पाएँ';

  @override
  String symptomsSelectedCount(int count) {
    return '$count चुने गए';
  }

  @override
  String get symptomsEmergencyShortcut => 'गंभीर लक्षण? इंतज़ार न करें — SOS का उपयोग करें।';

  @override
  String get symptomsNoMatch => 'आपकी खोज से कोई लक्षण नहीं मिला।';

  @override
  String get symptomsResultTitle => 'आपका मार्गदर्शन';

  @override
  String get symptomsWhatToDo => 'अभी क्या करें';

  @override
  String get symptomsWarningSignsTitle => 'यदि ये दिखें तो तुरंत SOS का उपयोग करें';

  @override
  String get symptomsSelectedTitle => 'आपके चुने गए लक्षण';

  @override
  String get symptomsFindFacility => 'नज़दीकी अस्पताल या कैंप खोजें';

  @override
  String get symptomsUseSos => 'SOS अलर्ट भेजें';

  @override
  String get symptomsStartOver => 'फिर से जाँचें';

  @override
  String get triageEmergency => 'आपातकाल';

  @override
  String get triageUrgent => 'ज़रूरी';

  @override
  String get triageRoutine => 'ज़रूरी नहीं';

  @override
  String get facilitiesTitle => 'नज़दीकी मदद';

  @override
  String get facilitiesSubtitle => 'आपके पास के अस्पताल और मेडिकल कैंप';

  @override
  String get facilitiesFilterAll => 'सभी';

  @override
  String get facilitiesFilterHospitals => 'अस्पताल';

  @override
  String get facilitiesFilterCamps => 'मेडिकल कैंप';

  @override
  String get facilitiesViewList => 'सूची';

  @override
  String get facilitiesViewMap => 'नक्शा';

  @override
  String get facilityTypeHospital => 'अस्पताल';

  @override
  String get facilityTypeCamp => 'मेडिकल कैंप';

  @override
  String get facilityEmergencyDept => 'आपातकालीन सेवा';

  @override
  String facilityOpenUntil(String time) {
    return '$time तक खुला';
  }

  @override
  String get facilitiesEmptyTitle => 'पास में कुछ नहीं मिला';

  @override
  String get facilitiesEmptyMessage =>
      'दूसरा फ़िल्टर आज़माएँ, या तुरंत मदद चाहिए तो SOS का उपयोग करें।';

  @override
  String get facilityServicesTitle => 'सेवाएँ';

  @override
  String get facilityAddressTitle => 'पता';

  @override
  String get facilityContactTitle => 'संपर्क';

  @override
  String get facilityCall => 'कॉल करें';

  @override
  String get facilityDirections => 'रास्ता देखें';

  @override
  String get facilityValidityTitle => 'खुलने का समय';

  @override
  String get facilityAbout => 'जानकारी';

  @override
  String get locationPermissionTitle => 'स्थान की अनुमति दें';

  @override
  String get locationPermissionMessage =>
      'MedAID आपके स्थान का उपयोग पास की मदद दिखाने और आपात स्थिति में स्वयंसेवकों को आप तक पहुँचाने के लिए करता है।';

  @override
  String get locationServicesOffTitle => 'लोकेशन चालू करें';

  @override
  String get locationServicesOffMessage => 'इस फ़ोन पर लोकेशन सेवाएँ बंद हैं।';

  @override
  String get profileTitle => 'प्रोफ़ाइल';

  @override
  String get profilePersonalDetails => 'व्यक्तिगत जानकारी';

  @override
  String get profileMedicalInfo => 'चिकित्सा जानकारी';

  @override
  String get profileMedicalInfoSubtitle => 'केवल आपकी अनुमति पर सहायकों के साथ साझा';

  @override
  String get profileEditTitle => 'जानकारी बदलें';

  @override
  String get profileSaved => 'आपके बदलाव सहेज लिए गए।';

  @override
  String get profileChangePassword => 'पासवर्ड बदलें';

  @override
  String get medicalDob => 'जन्म तिथि';

  @override
  String get medicalGender => 'लिंग';

  @override
  String get genderMale => 'पुरुष';

  @override
  String get genderFemale => 'महिला';

  @override
  String get genderOther => 'अन्य';

  @override
  String get genderPreferNotToSay => 'नहीं बताना चाहते';

  @override
  String get medicalBloodGroup => 'ब्लड ग्रुप';

  @override
  String get bloodGroupUnknown => 'पता नहीं';

  @override
  String get medicalAllergies => 'एलर्जी';

  @override
  String get medicalConditions => 'मौजूदा बीमारियाँ';

  @override
  String get medicalEmergencyContactName => 'आपातकालीन संपर्क का नाम';

  @override
  String get medicalEmergencyContactPhone => 'आपातकालीन संपर्क का फ़ोन';

  @override
  String get medicalShareConsent => 'मेरे अलर्ट पर आने वाले स्वयंसेवक के साथ यह जानकारी साझा करें';

  @override
  String get medicalShareConsentHelp =>
      'इसे केवल नियुक्त स्वयंसेवक और व्यवस्थापक देख सकते हैं, और केवल अलर्ट के दौरान।';

  @override
  String get medicalOptionalNote => 'सभी फ़ील्ड वैकल्पिक हैं।';

  @override
  String get errorFileTooLarge => 'यह फ़ाइल 5 MB से बड़ी है। कृपया छोटी फ़ाइल चुनें।';

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
  String get notificationsTitle => 'सूचनाएं';

  @override
  String get notificationsEmptyTitle => 'अभी कोई सूचना नहीं';

  @override
  String get notificationsEmptyMessage => 'आपातकाल और आपके खाते से जुड़ी जानकारी यहाँ दिखेगी।';

  @override
  String get notificationsMarkAllRead => 'सभी को पढ़ा हुआ करें';

  @override
  String get notificationsUnread => 'अपठित';

  @override
  String notificationsBellLabel(int count) {
    return 'सूचनाएं, $count अपठित';
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
  String get symptomsFirstAidTitle => 'अभी दी जा सकने वाली प्राथमिक चिकित्सा';

  @override
  String get exitConfirmTitle => 'MedAID बंद करें?';

  @override
  String get exitConfirmMessage => 'आप ऐप कभी भी दोबारा खोल सकते हैं। आपके अलर्ट चालू रहेंगे।';

  @override
  String get exitConfirmAction => 'बंद करें';

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
