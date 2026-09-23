const { EVENTS } = require('../../src/services/notification/notification.service');
const { TEMPLATES, render } = require('../../src/services/notification/templates');
const { LANGUAGES } = require('../../src/config/constants');

describe('notification templates', () => {
  it.each(Object.values(EVENTS))('%s has text for its audiences in every language', (type) => {
    const audiences = Object.entries(TEMPLATES[type] ?? {});
    expect(audiences.length).toBeGreaterThan(0);
    for (const [, template] of audiences) {
      for (const language of LANGUAGES) {
        expect(template.title[language]).toEqual(expect.any(String));
        expect(template.title[language].length).toBeGreaterThan(0);
        // Admin notices use the admin's own message as the body.
        if (type !== EVENTS.ADMIN_NOTICE) expect(template.body[language].length).toBeGreaterThan(0);
      }
    }
  });

  it('falls back to a generic localized text for an unknown event or audience', () => {
    expect(render('SOMETHING_NEW', 'USER', 'hi').title).toBe('MedAID');
    expect(render('ASSIGNMENT_NEW', 'USER', 'en').body).toBe('You have a new update.');
  });

  it('uses English when the language is unknown', () => {
    expect(render('EMERGENCY_CREATED', 'USER', 'fr').title).toBe('Alert sent');
  });
});
