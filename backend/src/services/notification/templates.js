const { ROLES } = require('../../config/constants');
const { pick } = require('../../utils/i18n');

/**
 * Notification text per event and audience (doc 19), in every app language.
 *
 * Texts are deliberately generic: no names, places or medical details, because
 * they can appear on a locked screen. IDs travel in `data` only.
 * Hindi and Marathi need native-speaker review before release (R-10).
 */
const t = (en, hi, mr) => ({ en, hi, mr });

const TEMPLATES = Object.freeze({
  EMERGENCY_CREATED: {
    [ROLES.USER]: {
      title: t('Alert sent', 'अलर्ट भेजा गया', 'अलर्ट पाठवला'),
      body: t(
        'We are finding a volunteer near you.',
        'हम आपके पास एक स्वयंसेवक ढूंढ रहे हैं।',
        'आम्ही तुमच्या जवळचा स्वयंसेवक शोधत आहोत.',
      ),
    },
    [ROLES.ADMIN]: {
      title: t('New emergency alert', 'नया आपातकालीन अलर्ट', 'नवीन आपत्कालीन अलर्ट'),
      body: t(
        'A new SOS alert was raised.',
        'एक नया SOS अलर्ट आया है।',
        'एक नवीन SOS अलर्ट आला आहे.',
      ),
    },
  },
  EMERGENCY_ASSIGNED: {
    [ROLES.USER]: {
      title: t('Volunteer alerted', 'स्वयंसेवक को सूचित किया गया', 'स्वयंसेवकाला कळवले'),
      body: t(
        'A nearby volunteer has been alerted. Waiting for them to accept.',
        'पास के एक स्वयंसेवक को सूचित किया गया है। उनकी स्वीकृति की प्रतीक्षा है।',
        'जवळच्या स्वयंसेवकाला कळवले आहे. त्यांच्या स्वीकृतीची प्रतीक्षा आहे.',
      ),
    },
  },
  EMERGENCY_ACCEPTED: {
    [ROLES.USER]: {
      title: t('Help is on the way', 'मदद आ रही है', 'मदत येत आहे'),
      body: t(
        'A volunteer accepted your alert and is coming to you.',
        'एक स्वयंसेवक ने आपका अलर्ट स्वीकार किया है और आपके पास आ रहे हैं।',
        'एका स्वयंसेवकाने तुमचा अलर्ट स्वीकारला आहे आणि ते तुमच्याकडे येत आहेत.',
      ),
    },
    [ROLES.ADMIN]: {
      title: t('Emergency accepted', 'आपातकाल स्वीकार किया गया', 'आपत्कालीन स्थिती स्वीकारली'),
      body: t(
        'A volunteer accepted an emergency.',
        'एक स्वयंसेवक ने आपातकाल स्वीकार किया।',
        'एका स्वयंसेवकाने आपत्कालीन स्थिती स्वीकारली.',
      ),
    },
  },
  EMERGENCY_IN_PROGRESS: {
    [ROLES.USER]: {
      title: t('Volunteer has arrived', 'स्वयंसेवक पहुंच गए हैं', 'स्वयंसेवक पोहोचले आहेत'),
      body: t(
        'The volunteer is with you now.',
        'स्वयंसेवक अब आपके साथ हैं।',
        'स्वयंसेवक आता तुमच्यासोबत आहेत.',
      ),
    },
  },
  EMERGENCY_RESOLVED: {
    [ROLES.USER]: {
      title: t('Emergency resolved', 'आपातकाल हल हुआ', 'आपत्कालीन स्थिती सुटली'),
      body: t(
        'Your alert was marked as resolved. Stay safe.',
        'आपका अलर्ट हल के रूप में चिह्नित किया गया। सुरक्षित रहें।',
        'तुमचा अलर्ट सुटला म्हणून नोंदवला आहे. सुरक्षित राहा.',
      ),
    },
    [ROLES.ADMIN]: {
      title: t('Emergency resolved', 'आपातकाल हल हुआ', 'आपत्कालीन स्थिती सुटली'),
      body: t('An emergency was resolved.', 'एक आपातकाल हल हुआ।', 'एक आपत्कालीन स्थिती सुटली.'),
    },
  },
  EMERGENCY_CANCELLED: {
    [ROLES.USER]: {
      title: t('Alert closed', 'अलर्ट बंद किया गया', 'अलर्ट बंद केला'),
      body: t(
        'Your alert was closed by the control room.',
        'आपका अलर्ट नियंत्रण कक्ष ने बंद किया।',
        'तुमचा अलर्ट नियंत्रण कक्षाने बंद केला.',
      ),
    },
    [ROLES.ADMIN]: {
      title: t('Alert cancelled', 'अलर्ट रद्द किया गया', 'अलर्ट रद्द केला'),
      body: t(
        'An emergency alert was cancelled.',
        'एक आपातकालीन अलर्ट रद्द किया गया।',
        'एक आपत्कालीन अलर्ट रद्द केला.',
      ),
    },
  },
  EMERGENCY_REASSIGNING: {
    [ROLES.USER]: {
      title: t(
        'Finding another volunteer',
        'दूसरा स्वयंसेवक ढूंढ रहे हैं',
        'दुसरा स्वयंसेवक शोधत आहोत',
      ),
      body: t(
        'Your alert is being sent to another volunteer nearby.',
        'आपका अलर्ट पास के दूसरे स्वयंसेवक को भेजा जा रहा है।',
        'तुमचा अलर्ट जवळच्या दुसऱ्या स्वयंसेवकाला पाठवला जात आहे.',
      ),
    },
    [ROLES.ADMIN]: {
      title: t(
        'Emergency reassigning',
        'आपातकाल पुनः सौंपा जा रहा है',
        'आपत्कालीन स्थिती पुन्हा सोपवत आहे',
      ),
      body: t(
        'A volunteer declined. The alert is going to the next volunteer.',
        'एक स्वयंसेवक ने मना किया। अलर्ट अगले स्वयंसेवक को जा रहा है।',
        'एका स्वयंसेवकाने नकार दिला. अलर्ट पुढच्या स्वयंसेवकाकडे जात आहे.',
      ),
    },
  },
  EMERGENCY_UNASSIGNED: {
    [ROLES.USER]: {
      title: t('Still looking for help', 'अभी भी मदद ढूंढ रहे हैं', 'अजूनही मदत शोधत आहोत'),
      body: t(
        'No volunteer is free nearby yet. The control room has been told. If life is at risk, call 112.',
        'अभी पास में कोई स्वयंसेवक उपलब्ध नहीं है। नियंत्रण कक्ष को सूचित किया गया है। जान को खतरा हो तो 112 पर कॉल करें।',
        'अजून जवळ कोणताही स्वयंसेवक उपलब्ध नाही. नियंत्रण कक्षाला कळवले आहे. जिवाला धोका असल्यास 112 वर कॉल करा.',
      ),
    },
    [ROLES.ADMIN]: {
      title: t(
        'No volunteer available',
        'कोई स्वयंसेवक उपलब्ध नहीं',
        'कोणताही स्वयंसेवक उपलब्ध नाही',
      ),
      body: t(
        'An emergency is waiting without a volunteer. Assign one manually.',
        'एक आपातकाल बिना स्वयंसेवक के प्रतीक्षा में है। कृपया स्वयं सौंपें।',
        'एक आपत्कालीन स्थिती स्वयंसेवकाविना प्रतीक्षेत आहे. कृपया स्वतः सोपवा.',
      ),
    },
  },
  EMERGENCY_ESCALATED: {
    [ROLES.ADMIN]: {
      title: t('Emergency escalated', 'आपातकाल आगे बढ़ाया गया', 'आपत्कालीन स्थिती पुढे पाठवली'),
      body: t(
        'Several volunteers did not respond in time. Please review.',
        'कई स्वयंसेवकों ने समय पर जवाब नहीं दिया। कृपया देखें।',
        'अनेक स्वयंसेवकांनी वेळेत प्रतिसाद दिला नाही. कृपया पाहा.',
      ),
    },
  },
  ASSIGNMENT_NEW: {
    [ROLES.VOLUNTEER]: {
      title: t(
        'New emergency near you',
        'आपके पास नया आपातकाल',
        'तुमच्या जवळ नवीन आपत्कालीन स्थिती',
      ),
      body: t(
        'Open MedAID and respond within 2 minutes.',
        'MedAID खोलें और 2 मिनट में जवाब दें।',
        'MedAID उघडा आणि 2 मिनिटांत प्रतिसाद द्या.',
      ),
    },
  },
  ASSIGNMENT_EXPIRING: {
    [ROLES.VOLUNTEER]: {
      title: t('Respond now', 'अभी जवाब दें', 'आता प्रतिसाद द्या'),
      body: t(
        'Your emergency assignment is about to expire.',
        'आपका आपातकालीन कार्य समाप्त होने वाला है।',
        'तुमचे आपत्कालीन काम संपणार आहे.',
      ),
    },
  },
  ASSIGNMENT_EXPIRED: {
    [ROLES.VOLUNTEER]: {
      title: t('Assignment expired', 'कार्य की समय सीमा समाप्त', 'कामाची मुदत संपली'),
      body: t(
        'It was not accepted in time and was passed to another volunteer.',
        'समय पर स्वीकार नहीं हुआ, इसलिए दूसरे स्वयंसेवक को दिया गया।',
        'वेळेत स्वीकारले नाही, त्यामुळे दुसऱ्या स्वयंसेवकाला दिले.',
      ),
    },
    [ROLES.ADMIN]: {
      title: t('Assignment timed out', 'कार्य का समय समाप्त', 'कामाची वेळ संपली'),
      body: t(
        'A volunteer did not respond in time. Reassigning.',
        'एक स्वयंसेवक ने समय पर जवाब नहीं दिया। पुनः सौंपा जा रहा है।',
        'एका स्वयंसेवकाने वेळेत प्रतिसाद दिला नाही. पुन्हा सोपवत आहे.',
      ),
    },
  },
  ASSIGNMENT_CANCELLED: {
    [ROLES.VOLUNTEER]: {
      title: t('Assignment cancelled', 'कार्य रद्द किया गया', 'काम रद्द केले'),
      body: t(
        'You no longer need to respond to this emergency.',
        'अब आपको इस आपातकाल पर जवाब देने की आवश्यकता नहीं है।',
        'आता तुम्हाला या आपत्कालीन स्थितीला प्रतिसाद देण्याची गरज नाही.',
      ),
    },
  },
  VERIFICATION_SUBMITTED: {
    [ROLES.ADMIN]: {
      title: t('Documents to review', 'दस्तावेज़ समीक्षा के लिए', 'कागदपत्रे तपासणीसाठी'),
      body: t(
        'A volunteer submitted documents for verification.',
        'एक स्वयंसेवक ने सत्यापन के लिए दस्तावेज़ जमा किए।',
        'एका स्वयंसेवकाने पडताळणीसाठी कागदपत्रे सादर केली.',
      ),
    },
  },
  VERIFICATION_APPROVED: {
    [ROLES.VOLUNTEER]: {
      title: t('You are verified', 'आप सत्यापित हैं', 'तुमची पडताळणी झाली'),
      body: t(
        'Go active to start receiving emergencies near you.',
        'पास के आपातकाल पाने के लिए सक्रिय हों।',
        'जवळच्या आपत्कालीन सूचना मिळवण्यासाठी सक्रिय व्हा.',
      ),
    },
  },
  VERIFICATION_REJECTED: {
    [ROLES.VOLUNTEER]: {
      title: t('Verification not approved', 'सत्यापन स्वीकृत नहीं हुआ', 'पडताळणी मंजूर झाली नाही'),
      body: t(
        'Open MedAID to see the reason and upload new documents.',
        'कारण देखने और नए दस्तावेज़ अपलोड करने के लिए MedAID खोलें।',
        'कारण पाहण्यासाठी आणि नवीन कागदपत्रे अपलोड करण्यासाठी MedAID उघडा.',
      ),
    },
  },
  ACCOUNT_SUSPENDED: {
    [ROLES.VOLUNTEER]: {
      title: t('Account suspended', 'खाता निलंबित', 'खाते निलंबित'),
      body: t(
        'Your account was suspended. Contact the control room.',
        'आपका खाता निलंबित किया गया है। नियंत्रण कक्ष से संपर्क करें।',
        'तुमचे खाते निलंबित केले आहे. नियंत्रण कक्षाशी संपर्क साधा.',
      ),
    },
  },
  ADMIN_NOTICE: {
    [ROLES.VOLUNTEER]: {
      title: t(
        'Notice from the control room',
        'नियंत्रण कक्ष से सूचना',
        'नियंत्रण कक्षाकडून सूचना',
      ),
      // The body is the admin's own message.
      body: t('', '', ''),
    },
  },
});

const FALLBACK = {
  title: t('MedAID', 'MedAID', 'MedAID'),
  body: t('You have a new update.', 'आपके लिए एक नई सूचना है।', 'तुमच्यासाठी एक नवीन सूचना आहे.'),
};

/** Text for `type` as seen by a recipient with `role`, in `language`. */
function render(type, role, language, { message } = {}) {
  const template = TEMPLATES[type]?.[role] ?? FALLBACK;
  return {
    title: pick(template.title, language),
    body: message ?? pick(template.body, language),
  };
}

module.exports = { TEMPLATES, render };
