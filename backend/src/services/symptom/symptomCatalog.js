/**
 * Symptom checker content (FR-03).
 *
 * CONTENT STATUS: PENDING_CLINICAL_REVIEW (A-05, OQ-13).
 * This is deliberately conservative triage: widely recognised red-flag
 * symptoms escalate to emergency help, and everything else points people to
 * a medical camp or hospital. It contains no diagnoses, medicines or dosages.
 * A qualified medical professional must review it before real-world use.
 */

const CONTENT_STATUS = 'PENDING_CLINICAL_REVIEW';

const LEVEL = Object.freeze({ EMERGENCY: 'EMERGENCY', URGENT: 'URGENT', ROUTINE: 'ROUTINE' });
const LEVEL_RANK = Object.freeze({ ROUTINE: 0, URGENT: 1, EMERGENCY: 2 });

const CATEGORIES = [
  { key: 'breathing_chest', name: { en: 'Breathing & chest', hi: 'साँस और सीना', mr: 'श्वास आणि छाती' } },
  { key: 'head_consciousness', name: { en: 'Head & consciousness', hi: 'सिर और होश', mr: 'डोके आणि शुद्ध' } },
  { key: 'injuries', name: { en: 'Injuries & bleeding', hi: 'चोट और खून बहना', mr: 'इजा आणि रक्तस्राव' } },
  { key: 'heat_hydration', name: { en: 'Heat & dehydration', hi: 'गर्मी और पानी की कमी', mr: 'उष्णता आणि पाण्याची कमतरता' } },
  { key: 'stomach', name: { en: 'Stomach', hi: 'पेट', mr: 'पोट' } },
  { key: 'skin_allergy', name: { en: 'Skin & allergy', hi: 'त्वचा और एलर्जी', mr: 'त्वचा आणि ॲलर्जी' } },
  { key: 'general', name: { en: 'General', hi: 'सामान्य', mr: 'सामान्य' } },
];

const symptom = (key, category, level, en, hi, mr) => ({ key, category, level, name: { en, hi, mr } });

const SYMPTOMS = [
  // Emergency red flags
  symptom('chest_pain', 'breathing_chest', LEVEL.EMERGENCY, 'Chest pain or pressure', 'सीने में दर्द या दबाव', 'छातीत दुखणे किंवा दाब'),
  symptom('severe_breathing_difficulty', 'breathing_chest', LEVEL.EMERGENCY, 'Severe difficulty breathing', 'साँस लेने में गंभीर तकलीफ़', 'श्वास घेण्यास तीव्र त्रास'),
  symptom('unresponsive', 'head_consciousness', LEVEL.EMERGENCY, 'Fainted or not responding', 'बेहोश या कोई प्रतिक्रिया नहीं', 'बेशुद्ध किंवा प्रतिसाद देत नाही'),
  symptom('stroke_signs', 'head_consciousness', LEVEL.EMERGENCY, 'Face drooping, arm weakness or slurred speech', 'चेहरा टेढ़ा होना, हाथ में कमज़ोरी या बोलने में लड़खड़ाहट', 'चेहरा वाकडा होणे, हातात अशक्तपणा किंवा बोलण्यात अडखळणे'),
  symptom('seizure', 'head_consciousness', LEVEL.EMERGENCY, 'Seizure (fits)', 'दौरा पड़ना', 'झटके येणे (फिट)'),
  symptom('head_injury_confusion', 'injuries', LEVEL.EMERGENCY, 'Head injury with confusion or vomiting', 'सिर पर चोट के साथ भ्रम या उल्टी', 'डोक्याला मार लागून गोंधळ किंवा उलटी'),
  symptom('severe_bleeding', 'injuries', LEVEL.EMERGENCY, 'Heavy bleeding that does not stop', 'ज़्यादा खून बहना जो रुक नहीं रहा', 'न थांबणारा जास्त रक्तस्राव'),
  symptom('serious_burn', 'injuries', LEVEL.EMERGENCY, 'Large or serious burn', 'बड़ा या गंभीर रूप से जलना', 'मोठी किंवा गंभीर भाजलेली जखम'),
  symptom('face_throat_swelling', 'skin_allergy', LEVEL.EMERGENCY, 'Swelling of face, lips or throat', 'चेहरे, होंठ या गले में सूजन', 'चेहरा, ओठ किंवा घसा सुजणे'),
  symptom('heat_confusion', 'heat_hydration', LEVEL.EMERGENCY, 'Very hot skin with confusion', 'शरीर बहुत गर्म और भ्रम की स्थिति', 'शरीर खूप गरम आणि गोंधळलेली अवस्था'),

  // Urgent: see a doctor soon
  symptom('breathless_cough', 'breathing_chest', LEVEL.URGENT, 'Cough with breathlessness', 'खाँसी के साथ साँस फूलना', 'खोकल्यासोबत धाप लागणे'),
  symptom('high_fever', 'general', LEVEL.URGENT, 'High fever', 'तेज़ बुखार', 'जास्त ताप'),
  symptom('repeated_vomiting', 'stomach', LEVEL.URGENT, 'Repeated vomiting or diarrhoea', 'बार-बार उल्टी या दस्त', 'वारंवार उलट्या किंवा जुलाब'),
  symptom('severe_stomach_pain', 'stomach', LEVEL.URGENT, 'Severe stomach pain', 'पेट में तेज़ दर्द', 'पोटात तीव्र वेदना'),
  symptom('possible_fracture', 'injuries', LEVEL.URGENT, 'Possible broken bone', 'हड्डी टूटने की आशंका', 'हाड मोडल्याची शक्यता'),
  symptom('deep_cut', 'injuries', LEVEL.URGENT, 'Deep cut or wound', 'गहरा कट या घाव', 'खोल कापलेली जखम'),
  symptom('animal_bite', 'injuries', LEVEL.URGENT, 'Animal bite', 'जानवर का काटना', 'प्राण्याचा चावा'),
  symptom('eye_injury', 'injuries', LEVEL.URGENT, 'Eye injury', 'आँख में चोट', 'डोळ्याला इजा'),
  symptom('dehydration_signs', 'heat_hydration', LEVEL.URGENT, 'Dizziness, very dry mouth or little urine', 'चक्कर, मुँह बहुत सूखना या पेशाब कम होना', 'चक्कर, तोंड खूप कोरडे पडणे किंवा लघवी कमी होणे'),

  // Routine: self-care and keep watch
  symptom('cough_cold', 'breathing_chest', LEVEL.ROUTINE, 'Cough or cold', 'खाँसी या ज़ुकाम', 'खोकला किंवा सर्दी'),
  symptom('headache', 'head_consciousness', LEVEL.ROUTINE, 'Headache', 'सिरदर्द', 'डोकेदुखी'),
  symptom('mild_fever', 'general', LEVEL.ROUTINE, 'Mild fever', 'हल्का बुखार', 'सौम्य ताप'),
  symptom('minor_cut', 'injuries', LEVEL.ROUTINE, 'Minor cut or scrape', 'छोटा कट या खरोंच', 'लहान जखम किंवा खरचटणे'),
  symptom('sprain', 'injuries', LEVEL.ROUTINE, 'Twisted ankle or sprain', 'मोच आना', 'मुरगळणे'),
  symptom('tiredness_heat', 'heat_hydration', LEVEL.ROUTINE, 'Tiredness from heat', 'गर्मी से थकान', 'उष्णतेमुळे थकवा'),
  symptom('mild_stomach_upset', 'stomach', LEVEL.ROUTINE, 'Mild stomach upset', 'पेट में हल्की गड़बड़ी', 'पोटात सौम्य त्रास'),
  symptom('sore_feet_blisters', 'skin_allergy', LEVEL.ROUTINE, 'Blisters or sore feet', 'पैरों में छाले या दर्द', 'पायाला फोड किंवा दुखणे'),
  symptom('mild_rash', 'skin_allergy', LEVEL.ROUTINE, 'Mild itching or rash', 'हल्की खुजली या चकत्ते', 'सौम्य खाज किंवा पुरळ'),
];

const GUIDANCE = {
  EMERGENCY: {
    title: { en: 'Get emergency help now', hi: 'तुरंत आपातकालीन मदद लें', mr: 'लगेच आपत्कालीन मदत घ्या' },
    message: {
      en: 'These symptoms can be serious. Use SOS to alert a volunteer, or call 108 (ambulance) or 112.',
      hi: 'ये लक्षण गंभीर हो सकते हैं। स्वयंसेवक को सूचित करने के लिए SOS का उपयोग करें, या 108 (एम्बुलेंस) या 112 पर कॉल करें।',
      mr: 'ही लक्षणे गंभीर असू शकतात. स्वयंसेवकाला कळवण्यासाठी SOS वापरा, किंवा 108 (रुग्णवाहिका) किंवा 112 वर कॉल करा.',
    },
    advice: [
      { en: 'Stay where you are if it is safe, so help can find you.', hi: 'अगर सुरक्षित हो तो वहीं रहें, ताकि मदद आप तक पहुँच सके।', mr: 'सुरक्षित असल्यास आहात तिथेच थांबा, म्हणजे मदत तुमच्यापर्यंत पोहोचू शकेल.' },
      { en: 'Ask people nearby to help and keep the person comfortable.', hi: 'आसपास के लोगों से मदद माँगें और व्यक्ति को आराम से रखें।', mr: 'आजूबाजूच्या लोकांची मदत घ्या आणि व्यक्तीला आरामात ठेवा.' },
      { en: 'Do not give food, drink or medicine unless a medical professional tells you to.', hi: 'जब तक कोई चिकित्सा पेशेवर न कहे, खाना, पानी या दवा न दें।', mr: 'वैद्यकीय तज्ज्ञाने सांगितल्याशिवाय अन्न, पाणी किंवा औषध देऊ नका.' },
    ],
    actions: ['SOS', 'CALL_EMERGENCY'],
  },
  URGENT: {
    title: { en: 'See a doctor soon', hi: 'जल्द डॉक्टर को दिखाएँ', mr: 'लवकर डॉक्टरांना दाखवा' },
    message: {
      en: 'Please visit the nearest hospital or medical camp as soon as you can.',
      hi: 'कृपया जितनी जल्दी हो सके नज़दीकी अस्पताल या मेडिकल कैंप जाएँ।',
      mr: 'कृपया शक्य तितक्या लवकर जवळच्या रुग्णालयात किंवा वैद्यकीय शिबिरात जा.',
    },
    advice: [
      { en: 'If you cannot get there safely, use SOS to get help.', hi: 'अगर आप सुरक्षित रूप से वहाँ नहीं जा सकते, तो मदद के लिए SOS का उपयोग करें।', mr: 'तुम्ही सुरक्षितपणे तिथे जाऊ शकत नसल्यास, मदतीसाठी SOS वापरा.' },
      { en: 'Go with a companion if possible.', hi: 'हो सके तो किसी साथी के साथ जाएँ।', mr: 'शक्य असल्यास सोबत कोणालातरी घेऊन जा.' },
      { en: 'Tell the doctor when your symptoms started.', hi: 'डॉक्टर को बताएँ कि लक्षण कब शुरू हुए।', mr: 'लक्षणे कधी सुरू झाली ते डॉक्टरांना सांगा.' },
    ],
    actions: ['FIND_FACILITY', 'SOS'],
  },
  ROUTINE: {
    title: { en: 'Take care and keep watch', hi: 'ध्यान रखें और लक्षणों पर नज़र रखें', mr: 'काळजी घ्या आणि लक्षणांवर लक्ष ठेवा' },
    message: {
      en: 'Your symptoms do not look urgent, but visit a medical camp if you do not feel better.',
      hi: 'आपके लक्षण गंभीर नहीं लगते, लेकिन आराम न मिले तो मेडिकल कैंप जाएँ।',
      mr: 'तुमची लक्षणे तातडीची वाटत नाहीत, पण बरे न वाटल्यास वैद्यकीय शिबिरात जा.',
    },
    advice: [
      { en: 'Rest in a shaded, less crowded place.', hi: 'छायादार, कम भीड़ वाली जगह पर आराम करें।', mr: 'सावलीत, कमी गर्दीच्या ठिकाणी विश्रांती घ्या.' },
      { en: 'Drink clean, safe water regularly.', hi: 'नियमित रूप से साफ़, सुरक्षित पानी पिएँ।', mr: 'नियमितपणे स्वच्छ, सुरक्षित पाणी प्या.' },
      { en: 'Keep a companion informed about how you feel.', hi: 'अपने साथी को बताते रहें कि आप कैसा महसूस कर रहे हैं।', mr: 'तुम्हाला कसे वाटते ते तुमच्या सोबत्याला सांगत रहा.' },
    ],
    actions: ['FIND_FACILITY'],
  },
};

const WARNING_SIGNS = [
  { en: 'Difficulty breathing', hi: 'साँस लेने में तकलीफ़', mr: 'श्वास घेण्यास त्रास' },
  { en: 'Confusion, fainting or severe drowsiness', hi: 'भ्रम, बेहोशी या बहुत ज़्यादा सुस्ती', mr: 'गोंधळ, बेशुद्धी किंवा खूप गुंगी' },
  { en: 'Chest pain', hi: 'सीने में दर्द', mr: 'छातीत दुखणे' },
  { en: 'Symptoms getting worse quickly', hi: 'लक्षण तेज़ी से बिगड़ना', mr: 'लक्षणे झपाट्याने वाढणे' },
];

const DISCLAIMER = {
  en: 'This is general guidance, not a medical diagnosis. If you are worried, seek medical help.',
  hi: 'यह सामान्य मार्गदर्शन है, चिकित्सा निदान नहीं। चिंता हो तो चिकित्सा सहायता लें।',
  mr: 'हे सामान्य मार्गदर्शन आहे, वैद्यकीय निदान नाही. काळजी वाटत असल्यास वैद्यकीय मदत घ्या.',
};

module.exports = {
  CONTENT_STATUS,
  LEVEL,
  LEVEL_RANK,
  CATEGORIES,
  SYMPTOMS,
  GUIDANCE,
  WARNING_SIGNS,
  DISCLAIMER,
};
