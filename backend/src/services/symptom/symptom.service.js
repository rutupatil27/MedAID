const catalog = require('./symptomCatalog');
const { FIRST_AID, MAX_FIRST_AID_STEPS } = require('./firstAidCatalog');
const { pick } = require('../../utils/i18n');

const symptomsByKey = new Map(catalog.SYMPTOMS.map((s) => [s.key, s]));

function listSymptoms(language) {
  return {
    contentStatus: catalog.CONTENT_STATUS,
    categories: catalog.CATEGORIES.map((category) => ({
      key: category.key,
      name: pick(category.name, language),
      symptoms: catalog.SYMPTOMS.filter((s) => s.category === category.key).map((s) => ({
        key: s.key,
        name: pick(s.name, language),
      })),
    })),
  };
}

/**
 * Conservative rule-based triage. The highest level among the selected
 * symptoms wins. Vulnerable groups and symptoms lasting 3+ days are never
 * left at ROUTINE.
 */
function evaluate({ symptoms, ageGroup = 'ADULT', pregnant = false, durationDays = 0 }) {
  const selected = symptoms.map((key) => symptomsByKey.get(key)).filter(Boolean);

  let level = selected.reduce(
    (highest, s) => (catalog.LEVEL_RANK[s.level] > catalog.LEVEL_RANK[highest] ? s.level : highest),
    catalog.LEVEL.ROUTINE,
  );

  const reasons = [];
  if (level === catalog.LEVEL.ROUTINE) {
    if (ageGroup === 'YOUNG_CHILD' || ageGroup === 'OLDER_ADULT') reasons.push('VULNERABLE_AGE');
    if (pregnant) reasons.push('PREGNANCY');
    if (durationDays >= 3) reasons.push('LONG_DURATION');
    if (reasons.length > 0) level = catalog.LEVEL.URGENT;
  }

  return {
    level,
    escalationReasons: reasons,
    redFlags: selected.filter((s) => s.level === catalog.LEVEL.EMERGENCY),
    selected,
  };
}

/**
 * First-aid steps for what was selected, most serious symptom first, with
 * duplicates removed and the list kept short enough to act on.
 */
function firstAidFor(selected, language) {
  const ordered = [...selected].sort(
    (a, b) => catalog.LEVEL_RANK[b.level] - catalog.LEVEL_RANK[a.level],
  );
  const steps = [];
  for (const symptom of ordered) {
    for (const step of FIRST_AID[symptom.key] ?? []) {
      const text = pick(step, language);
      if (text && !steps.includes(text)) steps.push(text);
    }
  }
  return steps.slice(0, MAX_FIRST_AID_STEPS);
}

function checkSymptoms(input, language) {
  const result = evaluate(input);
  const guidance = catalog.GUIDANCE[result.level];

  return {
    contentStatus: catalog.CONTENT_STATUS,
    level: result.level,
    title: pick(guidance.title, language),
    message: pick(guidance.message, language),
    advice: guidance.advice.map((text) => pick(text, language)),
    firstAid: firstAidFor(result.selected, language),
    actions: guidance.actions,
    warningSigns: catalog.WARNING_SIGNS.map((text) => pick(text, language)),
    redFlags: result.redFlags.map((s) => pick(s.name, language)),
    escalationReasons: result.escalationReasons,
    selectedSymptoms: result.selected.map((s) => ({ key: s.key, name: pick(s.name, language) })),
    disclaimer: pick(catalog.DISCLAIMER, language),
  };
}

module.exports = {
  listSymptoms,
  evaluate,
  checkSymptoms,
  firstAidFor,
  symptomKeys: [...symptomsByKey.keys()],
};
