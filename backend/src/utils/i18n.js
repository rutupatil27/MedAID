const { LANGUAGES } = require('../config/constants');

/**
 * Language for backend-authored content (symptom guidance, notifications).
 * Error codes stay language-neutral; only content is localized here.
 */
function resolveLanguage(req) {
  const header = req.get?.('accept-language') ?? '';
  for (const part of header.split(',')) {
    const code = part.trim().slice(0, 2).toLowerCase();
    if (LANGUAGES.includes(code)) return code;
  }
  return LANGUAGES.includes(req.user?.preferredLanguage) ? req.user.preferredLanguage : 'en';
}

/** Picks a translation from `{ en, hi, mr }`, falling back to English. */
function pick(text, language) {
  return text?.[language] ?? text?.en ?? '';
}

module.exports = { resolveLanguage, pick };
