const request = require('supertest');
const { createApp } = require('../../src/app');
const { evaluate } = require('../../src/services/symptom/symptom.service');
const { useTestDatabase } = require('../helpers/db');
const { createAccount } = require('../helpers/factories');

describe('Symptom checker', () => {
  useTestDatabase();
  const app = createApp();

  it('lists localized symptom categories for users', async () => {
    const { auth } = await createAccount();

    const en = await request(app).get('/api/v1/symptoms').set('Authorization', auth);
    const hi = await request(app)
      .get('/api/v1/symptoms')
      .set('Authorization', auth)
      .set('Accept-Language', 'hi');

    expect(en.status).toBe(200);
    expect(en.body.data.contentStatus).toBe('PENDING_CLINICAL_REVIEW');
    const enNames = en.body.data.categories.flatMap((c) => c.symptoms.map((s) => s.name));
    const hiNames = hi.body.data.categories.flatMap((c) => c.symptoms.map((s) => s.name));
    expect(enNames).toContain('Chest pain or pressure');
    expect(hiNames).toContain('सीने में दर्द या दबाव');
  });

  it('escalates red-flag symptoms to EMERGENCY with SOS guidance', async () => {
    const { auth } = await createAccount();

    const res = await request(app)
      .post('/api/v1/symptoms/check')
      .set('Authorization', auth)
      .set('Accept-Language', 'mr')
      .send({ symptoms: ['headache', 'chest_pain'] });

    expect(res.status).toBe(200);
    expect(res.body.data).toMatchObject({ level: 'EMERGENCY', actions: ['SOS', 'CALL_EMERGENCY'] });
    expect(res.body.data.redFlags).toEqual(['छातीत दुखणे किंवा दाब']);
    expect(res.body.data.disclaimer).toMatch(/निदान नाही/);
  });

  it('rejects unknown symptoms and empty selections', async () => {
    const { auth } = await createAccount();

    const unknown = await request(app)
      .post('/api/v1/symptoms/check')
      .set('Authorization', auth)
      .send({ symptoms: ['made_up'] });
    const empty = await request(app)
      .post('/api/v1/symptoms/check')
      .set('Authorization', auth)
      .send({ symptoms: [] });

    expect(unknown.status).toBe(400);
    expect(empty.status).toBe(400);
  });

  it('is a USER-only feature', async () => {
    const { auth } = await createAccount({ role: 'VOLUNTEER' });

    const res = await request(app).get('/api/v1/symptoms').set('Authorization', auth);

    expect(res.status).toBe(403);
  });

  describe('triage rules', () => {
    it('never leaves vulnerable groups or long-lasting symptoms at ROUTINE', () => {
      expect(evaluate({ symptoms: ['headache'] }).level).toBe('ROUTINE');
      expect(evaluate({ symptoms: ['headache'], ageGroup: 'OLDER_ADULT' }).level).toBe('URGENT');
      expect(evaluate({ symptoms: ['headache'], ageGroup: 'YOUNG_CHILD' }).level).toBe('URGENT');
      expect(evaluate({ symptoms: ['mild_fever'], pregnant: true }).level).toBe('URGENT');
      expect(evaluate({ symptoms: ['cough_cold'], durationDays: 3 }).level).toBe('URGENT');
    });

    it('uses the highest level among selected symptoms', () => {
      expect(evaluate({ symptoms: ['minor_cut', 'deep_cut'] }).level).toBe('URGENT');
      expect(evaluate({ symptoms: ['deep_cut', 'severe_bleeding'] }).level).toBe('EMERGENCY');
    });
  });

  describe('first aid', () => {
    const check = (auth, body, language = 'en') =>
      request(app)
        .post('/api/v1/symptoms/check')
        .set('Authorization', auth)
        .set('Accept-Language', language)
        .send({ ageGroup: 'ADULT', pregnant: false, durationDays: 0, ...body });

    it('returns steps for what was selected, in the chosen language', async () => {
      const { auth } = await createAccount();

      const en = await check(auth, { symptoms: ['severe_bleeding'] });
      const mr = await check(auth, { symptoms: ['severe_bleeding'] }, 'mr');

      expect(en.body.data.firstAid[0]).toBe('Press hard on the wound with a clean cloth.');
      expect(en.body.data.firstAid).toContain('Raise the injured part above the heart if you can.');
      expect(mr.body.data.firstAid[0]).not.toBe(en.body.data.firstAid[0]);
      expect(mr.body.data.firstAid).toHaveLength(en.body.data.firstAid.length);
    });

    it('puts the most serious symptom first and keeps the list short', async () => {
      const { auth } = await createAccount();

      const res = await check(auth, {
        symptoms: ['sore_feet_blisters', 'mild_fever', 'unresponsive', 'deep_cut'],
      });

      expect(res.body.data.firstAid[0]).toBe('Check whether they are breathing.');
      expect(res.body.data.firstAid.length).toBeLessThanOrEqual(6);
    });

    it('never names a medicine or a dose (content rule, doc 25)', async () => {
      const { auth } = await createAccount();
      const { SYMPTOMS } = require('../../src/services/symptom/symptomCatalog');
      const forbidden =
        /\b(\d+\s?(mg|ml|mcg|g)\b|paracetamol|acetaminophen|ibuprofen|aspirin|antibiotic|tablet|syrup|injection|dose|dosage)\b/i;

      for (const symptom of SYMPTOMS) {
        const res = await check(auth, { symptoms: [symptom.key] });
        for (const step of res.body.data.firstAid) {
          expect(step).not.toMatch(forbidden);
          // Medicine may only be mentioned as something already prescribed to
          // that person, or as something not to give. Never as our own advice
          // to take something.
          if (/\bmedicine\b/i.test(step)) expect(step).toMatch(/prescribed|do not/i);
        }
      }
    });

    it('offers steps for every symptom in the catalog', async () => {
      const { auth } = await createAccount();
      const { SYMPTOMS } = require('../../src/services/symptom/symptomCatalog');

      const missing = [];
      for (const symptom of SYMPTOMS) {
        const res = await check(auth, { symptoms: [symptom.key] });
        if (res.body.data.firstAid.length === 0) missing.push(symptom.key);
      }

      expect(missing).toEqual([]);
    });
  });
});
