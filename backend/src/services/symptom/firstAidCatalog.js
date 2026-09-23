/**
 * Short first-aid steps per symptom (FR-03).
 *
 * CONTENT STATUS: PENDING_CLINICAL_REVIEW (A-05, OQ-13).
 * These are widely taught first-aid actions a bystander can safely take while
 * help is on the way. Deliberately excluded, and not to be added without a
 * clinician's sign-off:
 *   - any medicine name, dose or prescription
 *   - anything invasive or requiring training
 *   - anything that delays professional care
 * "Do not" steps matter as much as the others: they prevent the common
 * mistakes (moving a fracture, ice on burns, water to an unconscious person).
 * Hindi and Marathi need a native-speaker review (R-10).
 */
const t = (en, hi, mr) => ({ en, hi, mr });

const FIRST_AID = Object.freeze({
  // ---- Emergency ------------------------------------------------------------
  chest_pain: [
    t(
      'Help them sit down and rest. Do not let them walk about.',
      'उन्हें बैठाकर आराम दें। उन्हें चलने-फिरने न दें।',
      'त्यांना बसवून आराम द्या. त्यांना चालू-फिरू देऊ नका.',
    ),
    t(
      'Loosen tight clothing and keep the area around them clear.',
      'तंग कपड़े ढीले करें और आसपास भीड़ न लगने दें।',
      'घट्ट कपडे सैल करा आणि आजूबाजूला गर्दी होऊ देऊ नका.',
    ),
    t(
      'If a doctor has prescribed them heart medicine, let them take it as directed.',
      'अगर डॉक्टर ने उन्हें दिल की दवा दी है, तो निर्देश के अनुसार लेने दें।',
      'डॉक्टरांनी हृदयाचे औषध दिले असल्यास, सांगितल्याप्रमाणे घेऊ द्या.',
    ),
  ],
  severe_breathing_difficulty: [
    t(
      'Help them sit upright, leaning slightly forward.',
      'उन्हें सीधा बैठाएँ, थोड़ा आगे की ओर झुकाकर।',
      'त्यांना सरळ बसवा, थोडे पुढे झुकवून.',
    ),
    t(
      'Move them to fresh air, away from the crowd.',
      'उन्हें भीड़ से दूर खुली हवा में ले जाएँ।',
      'त्यांना गर्दीपासून दूर मोकळ्या हवेत न्या.',
    ),
    t(
      'If they have their own inhaler, help them use it.',
      'अगर उनके पास अपना इनहेलर है, तो उसे लेने में मदद करें।',
      'त्यांच्याकडे स्वतःचा इनहेलर असल्यास, वापरण्यास मदत करा.',
    ),
  ],
  unresponsive: [
    t(
      'Check whether they are breathing.',
      'देखें कि वे साँस ले रहे हैं या नहीं।',
      'ते श्वास घेत आहेत का ते पाहा.',
    ),
    t(
      'If they are breathing, roll them gently onto their side.',
      'अगर साँस चल रही है, तो उन्हें धीरे से करवट पर लिटाएँ।',
      'श्वास सुरू असल्यास, त्यांना हळूवारपणे कुशीवर वळवा.',
    ),
    t(
      'Do not put water, food or anything else in their mouth.',
      'उनके मुँह में पानी, खाना या कुछ भी न डालें।',
      'त्यांच्या तोंडात पाणी, अन्न किंवा काहीही घालू नका.',
    ),
  ],
  stroke_signs: [
    t(
      'Note the time the symptoms started — doctors need it.',
      'लक्षण शुरू होने का समय याद रखें — डॉक्टर को यह जानना ज़रूरी है।',
      'लक्षणे कधी सुरू झाली ती वेळ लक्षात ठेवा — डॉक्टरांना ती आवश्यक असते.',
    ),
    t(
      'Keep them sitting, supported and calm.',
      'उन्हें सहारे के साथ बैठाकर शांत रखें।',
      'त्यांना आधार देऊन बसवा आणि शांत ठेवा.',
    ),
    t(
      'Do not give food, drink or medicine.',
      'खाना, पानी या दवा न दें।',
      'अन्न, पाणी किंवा औषध देऊ नका.',
    ),
  ],
  seizure: [
    t(
      'Move hard objects away and cushion their head.',
      'आसपास से सख़्त चीज़ें हटाएँ और सिर के नीचे कुछ नरम रखें।',
      'कठीण वस्तू बाजूला करा आणि डोक्याखाली मऊ काहीतरी ठेवा.',
    ),
    t(
      'Do not hold them down or put anything in their mouth.',
      'उन्हें ज़बरदस्ती न पकड़ें और मुँह में कुछ न डालें।',
      'त्यांना जबरदस्तीने धरू नका आणि तोंडात काहीही घालू नका.',
    ),
    t(
      'When the shaking stops, turn them onto their side.',
      'झटके रुकने पर उन्हें करवट पर लिटाएँ।',
      'झटके थांबल्यावर त्यांना कुशीवर वळवा.',
    ),
  ],
  head_injury_confusion: [
    t(
      'Keep them still and do not leave them alone.',
      'उन्हें स्थिर रखें और अकेला न छोड़ें।',
      'त्यांना स्थिर ठेवा आणि एकटे सोडू नका.',
    ),
    t(
      'Press a clean cloth on any bleeding.',
      'खून बह रहा हो तो साफ़ कपड़े से दबाएँ।',
      'रक्तस्राव होत असल्यास स्वच्छ कापडाने दाब द्या.',
    ),
    t(
      'Do not give food or drink, and do not let them drive.',
      'खाना-पानी न दें और उन्हें गाड़ी न चलाने दें।',
      'अन्न-पाणी देऊ नका आणि त्यांना वाहन चालवू देऊ नका.',
    ),
  ],
  severe_bleeding: [
    t(
      'Press hard on the wound with a clean cloth.',
      'साफ़ कपड़े से घाव पर ज़ोर से दबाएँ।',
      'स्वच्छ कापडाने जखमेवर जोराने दाब द्या.',
    ),
    t(
      'Keep pressing. Add more cloth on top instead of removing it.',
      'दबाव बनाए रखें। कपड़ा हटाने के बजाय ऊपर और कपड़ा रखें।',
      'दाब कायम ठेवा. कापड काढण्याऐवजी वर आणखी कापड ठेवा.',
    ),
    t(
      'Raise the injured part above the heart if you can.',
      'हो सके तो घायल हिस्से को दिल से ऊपर उठाकर रखें।',
      'शक्य असल्यास जखमी भाग हृदयाच्या वर उचलून धरा.',
    ),
  ],
  serious_burn: [
    t(
      'Cool the burn under clean running water for 20 minutes.',
      'जले हुए हिस्से को 20 मिनट तक साफ़ बहते पानी में रखें।',
      'भाजलेला भाग 20 मिनिटे स्वच्छ वाहत्या पाण्याखाली धरा.',
    ),
    t(
      'Remove rings, bangles or tight clothing near the burn.',
      'जले हिस्से के पास की अंगूठी, चूड़ी या तंग कपड़े हटा दें।',
      'भाजलेल्या भागाजवळील अंगठी, बांगड्या किंवा घट्ट कपडे काढा.',
    ),
    t(
      'Do not apply ice, oil, toothpaste or butter. Cover loosely with a clean cloth.',
      'बर्फ़, तेल, टूथपेस्ट या मक्खन न लगाएँ। साफ़ कपड़े से ढीला ढक दें।',
      'बर्फ, तेल, टूथपेस्ट किंवा लोणी लावू नका. स्वच्छ कापडाने सैलसर झाका.',
    ),
  ],
  face_throat_swelling: [
    t(
      'If they carry their own allergy injector, help them use it at once.',
      'अगर उनके पास अपना एलर्जी इंजेक्टर है, तो तुरंत लेने में मदद करें।',
      'त्यांच्याकडे स्वतःचा ॲलर्जी इंजेक्टर असल्यास, लगेच वापरण्यास मदत करा.',
    ),
    t(
      'Keep them sitting upright and calm.',
      'उन्हें सीधा बैठाकर शांत रखें।',
      'त्यांना सरळ बसवा आणि शांत ठेवा.',
    ),
    t(
      'Do not give anything to eat or drink.',
      'खाने या पीने के लिए कुछ न दें।',
      'खाण्या-पिण्यासाठी काहीही देऊ नका.',
    ),
  ],
  heat_confusion: [
    t(
      'Move them into shade immediately.',
      'उन्हें तुरंत छाया में ले जाएँ।',
      'त्यांना लगेच सावलीत न्या.',
    ),
    t(
      'Cool the skin with wet cloths or water and fan them.',
      'गीले कपड़े या पानी से शरीर ठंडा करें और हवा करें।',
      'ओल्या कापडाने किंवा पाण्याने शरीर थंड करा आणि वारा घाला.',
    ),
    t(
      'Do not force a confused person to drink.',
      'भ्रम की स्थिति में किसी को ज़बरदस्ती पानी न पिलाएँ।',
      'गोंधळलेल्या व्यक्तीला जबरदस्तीने पाणी पाजू नका.',
    ),
  ],

  // ---- Urgent ---------------------------------------------------------------
  breathless_cough: [
    t(
      'Sit upright and rest; avoid smoke and crowded places.',
      'सीधे बैठकर आराम करें; धुएँ और भीड़ से बचें।',
      'सरळ बसून विश्रांती घ्या; धूर आणि गर्दी टाळा.',
    ),
    t('Sip water slowly.', 'धीरे-धीरे पानी पिएँ।', 'हळूहळू पाणी प्या.'),
  ],
  high_fever: [
    t(
      'Rest in a cool, shaded place.',
      'ठंडी, छायादार जगह पर आराम करें।',
      'थंड, सावलीच्या ठिकाणी विश्रांती घ्या.',
    ),
    t(
      'Sip water or ORS often.',
      'थोड़ी-थोड़ी देर में पानी या ओआरएस पिएँ।',
      'थोड्या थोड्या वेळाने पाणी किंवा ओआरएस प्या.',
    ),
    t(
      'Wipe the skin with a damp cloth to cool down.',
      'शरीर को ठंडा करने के लिए गीले कपड़े से पोंछें।',
      'शरीर थंड करण्यासाठी ओल्या कापडाने पुसा.',
    ),
  ],
  repeated_vomiting: [
    t(
      'Take small sips of ORS or clean water often.',
      'थोड़ी-थोड़ी मात्रा में ओआरएस या साफ़ पानी बार-बार लें।',
      'ओआरएस किंवा स्वच्छ पाणी थोडे थोडे वारंवार घ्या.',
    ),
    t(
      'Avoid oily or heavy food for now.',
      'अभी तैलीय या भारी खाना न खाएँ।',
      'सध्या तेलकट किंवा जड अन्न टाळा.',
    ),
    t(
      'Wash hands well so others do not fall ill.',
      'हाथ अच्छी तरह धोएँ ताकि दूसरों को न लगे।',
      'हात नीट धुवा म्हणजे इतरांना त्रास होणार नाही.',
    ),
  ],
  severe_stomach_pain: [
    t(
      'Rest and avoid solid food until a doctor sees you.',
      'डॉक्टर को दिखाने तक आराम करें और ठोस खाना न खाएँ।',
      'डॉक्टरांना दाखवेपर्यंत विश्रांती घ्या आणि घन अन्न टाळा.',
    ),
    t(
      'Do not put a hot water bottle on the painful area.',
      'दर्द वाली जगह पर गर्म पानी की बोतल न रखें।',
      'दुखणाऱ्या भागावर गरम पाण्याची बाटली ठेवू नका.',
    ),
  ],
  possible_fracture: [
    t(
      'Keep the limb still and supported.',
      'हाथ या पैर को हिलने न दें, सहारा देकर रखें।',
      'हात किंवा पाय हलू देऊ नका, आधार देऊन ठेवा.',
    ),
    t(
      'Put a cold pack wrapped in cloth over the area.',
      'कपड़े में लपेटकर ठंडी सिकाई करें।',
      'कापडात गुंडाळून थंड शेक द्या.',
    ),
    t(
      'Do not try to straighten it or walk on it.',
      'उसे सीधा करने या उस पर चलने की कोशिश न करें।',
      'तो सरळ करण्याचा किंवा त्यावर चालण्याचा प्रयत्न करू नका.',
    ),
  ],
  deep_cut: [
    t(
      'Press with a clean cloth until the bleeding slows.',
      'खून कम होने तक साफ़ कपड़े से दबाएँ।',
      'रक्तस्राव कमी होईपर्यंत स्वच्छ कापडाने दाब द्या.',
    ),
    t(
      'Rinse gently with clean water, then cover with a clean dressing.',
      'साफ़ पानी से हल्के से धोएँ, फिर साफ़ पट्टी से ढकें।',
      'स्वच्छ पाण्याने हळूवार धुवा, नंतर स्वच्छ पट्टीने झाका.',
    ),
    t(
      'Do not pull out anything stuck deep in the wound.',
      'घाव में गहराई तक धँसी चीज़ को बाहर न निकालें।',
      'जखमेत खोलवर रुतलेली वस्तू बाहेर काढू नका.',
    ),
  ],
  animal_bite: [
    t(
      'Wash the bite with soap under running water for 15 minutes.',
      'काटे हुए हिस्से को साबुन और बहते पानी से 15 मिनट धोएँ।',
      'चावलेला भाग साबण आणि वाहत्या पाण्याने 15 मिनिटे धुवा.',
    ),
    t('Cover it with a clean cloth.', 'उसे साफ़ कपड़े से ढक दें।', 'तो स्वच्छ कापडाने झाका.'),
    t(
      'Get medical care the same day, even for a small bite.',
      'छोटा काटा हो तब भी उसी दिन इलाज कराएँ।',
      'लहान चावा असला तरी त्याच दिवशी उपचार घ्या.',
    ),
  ],
  eye_injury: [
    t(
      'Do not rub or press the eye.',
      'आँख को न रगड़ें और न दबाएँ।',
      'डोळा चोळू नका किंवा दाबू नका.',
    ),
    t(
      'If something splashed in, rinse with clean water for 15 minutes.',
      'कुछ छींटा पड़ा हो तो 15 मिनट तक साफ़ पानी से धोएँ।',
      'काही उडाले असल्यास 15 मिनिटे स्वच्छ पाण्याने धुवा.',
    ),
    t(
      'Do not remove anything stuck in the eye; cover it lightly.',
      'आँख में धँसी चीज़ न निकालें; हल्के से ढक दें।',
      'डोळ्यात रुतलेली वस्तू काढू नका; हलकेच झाका.',
    ),
  ],
  dehydration_signs: [
    t(
      'Sip ORS or clean water steadily.',
      'लगातार थोड़ा-थोड़ा ओआरएस या साफ़ पानी पिएँ।',
      'सतत थोडे थोडे ओआरएस किंवा स्वच्छ पाणी प्या.',
    ),
    t(
      'Rest in shade and loosen tight clothes.',
      'छाया में आराम करें और तंग कपड़े ढीले करें।',
      'सावलीत विश्रांती घ्या आणि घट्ट कपडे सैल करा.',
    ),
  ],

  // ---- Routine --------------------------------------------------------------
  cough_cold: [
    t(
      'Rest and drink warm fluids.',
      'आराम करें और गर्म तरल पदार्थ लें।',
      'विश्रांती घ्या आणि कोमट पेय घ्या.',
    ),
    t(
      'Cover your mouth when you cough and wash your hands.',
      'खाँसते समय मुँह ढकें और हाथ धोएँ।',
      'खोकताना तोंड झाका आणि हात धुवा.',
    ),
  ],
  headache: [
    t(
      'Rest in a quiet, shaded place.',
      'शांत, छायादार जगह पर आराम करें।',
      'शांत, सावलीच्या ठिकाणी विश्रांती घ्या.',
    ),
    t(
      'Drink water — heat and dehydration often cause headaches.',
      'पानी पिएँ — गर्मी और पानी की कमी से अक्सर सिरदर्द होता है।',
      'पाणी प्या — उष्णता आणि पाण्याच्या कमतरतेमुळे अनेकदा डोके दुखते.',
    ),
  ],
  mild_fever: [
    t(
      'Rest and drink fluids often.',
      'आराम करें और बार-बार तरल पदार्थ लें।',
      'विश्रांती घ्या आणि वारंवार द्रव घ्या.',
    ),
    t(
      'Keep cool with a damp cloth and light clothing.',
      'गीले कपड़े और हल्के कपड़ों से ठंडक रखें।',
      'ओले कापड आणि हलके कपडे वापरून थंड राहा.',
    ),
  ],
  minor_cut: [
    t(
      'Wash around the cut with clean water.',
      'कट के आसपास साफ़ पानी से धोएँ।',
      'जखमेभोवती स्वच्छ पाण्याने धुवा.',
    ),
    t('Cover it with a clean dressing.', 'साफ़ पट्टी से ढक दें।', 'स्वच्छ पट्टीने झाका.'),
    t(
      'Watch for redness, swelling or pus over the next days.',
      'अगले दिनों में लाली, सूजन या पीप पर नज़र रखें।',
      'पुढील दिवसांत लालसरपणा, सूज किंवा पू यावर लक्ष ठेवा.',
    ),
  ],
  sprain: [
    t(
      'Rest the joint and avoid walking on it.',
      'जोड़ को आराम दें और उस पर न चलें।',
      'सांध्याला आराम द्या आणि त्यावर चालू नका.',
    ),
    t(
      'Cold pack wrapped in cloth for 15-20 minutes.',
      'कपड़े में लपेटकर 15-20 मिनट ठंडी सिकाई करें।',
      'कापडात गुंडाळून 15-20 मिनिटे थंड शेक द्या.',
    ),
    t('Keep it raised when you sit.', 'बैठते समय उसे ऊपर उठाकर रखें।', 'बसताना तो उंच ठेवा.'),
  ],
  tiredness_heat: [
    t(
      'Sit in shade and loosen your clothing.',
      'छाया में बैठें और कपड़े ढीले करें।',
      'सावलीत बसा आणि कपडे सैल करा.',
    ),
    t('Sip water or ORS.', 'पानी या ओआरएस पिएँ।', 'पाणी किंवा ओआरएस प्या.'),
    t(
      'Wet your face, neck and arms.',
      'चेहरा, गर्दन और हाथ गीले करें।',
      'चेहरा, मान आणि हात ओले करा.',
    ),
  ],
  mild_stomach_upset: [
    t(
      'Sip water often and eat light food.',
      'बार-बार पानी पिएँ और हल्का खाना खाएँ।',
      'वारंवार पाणी प्या आणि हलके अन्न खा.',
    ),
    t(
      'Avoid oily or street food today.',
      'आज तैलीय या बाहर का खाना न खाएँ।',
      'आज तेलकट किंवा बाहेरचे अन्न टाळा.',
    ),
  ],
  sore_feet_blisters: [
    t(
      'Clean the area and cover the blister; do not burst it.',
      'जगह साफ़ करें और छाले को ढक दें; उसे फोड़ें नहीं।',
      'जागा स्वच्छ करा आणि फोड झाका; तो फोडू नका.',
    ),
    t(
      'Wear dry socks and rest your feet when you can.',
      'सूखे मोज़े पहनें और जब हो सके पैरों को आराम दें।',
      'कोरडे मोजे घाला आणि शक्य तेव्हा पायांना आराम द्या.',
    ),
  ],
  mild_rash: [
    t(
      'Wash the area with clean water and pat it dry.',
      'उस जगह को साफ़ पानी से धोकर थपथपाकर सुखाएँ।',
      'तो भाग स्वच्छ पाण्याने धुवा आणि हळूच कोरडा करा.',
    ),
    t('Try not to scratch it.', 'खुजलाने से बचें।', 'खाजवू नका.'),
    t(
      'Get help at once if your face swells or breathing changes.',
      'चेहरे पर सूजन या साँस में बदलाव हो तो तुरंत मदद लें।',
      'चेहरा सुजल्यास किंवा श्वासात बदल झाल्यास लगेच मदत घ्या.',
    ),
  ],
});

/** Keeps the result readable on a phone during an emergency. */
const MAX_FIRST_AID_STEPS = 6;

module.exports = { FIRST_AID, MAX_FIRST_AID_STEPS };
