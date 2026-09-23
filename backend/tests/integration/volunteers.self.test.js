const request = require('supertest');
const { createApp } = require('../../src/app');
const { Volunteer, VolunteerDocument } = require('../../src/models');
const { setDocumentStorage } = require('../../src/integrations/cloudinary/documentStorage');
const { useTestDatabase } = require('../helpers/db');
const { createAccount } = require('../helpers/factories');
const { CENTER, COMPLETE_PROFILE, createVolunteer } = require('../helpers/scenario');

const PNG = Buffer.concat([
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  Buffer.alloc(64),
]);
const PDF = Buffer.concat([Buffer.from('%PDF-1.7\n'), Buffer.alloc(64)]);

describe('Volunteer self-service', () => {
  useTestDatabase();
  const app = createApp();
  let stored;

  beforeEach(() => {
    stored = { uploads: [], removed: [] };
    setDocumentStorage({
      async upload({ publicIdHint, mimeType }) {
        stored.uploads.push(publicIdHint);
        return {
          publicId: publicIdHint,
          resourceType: mimeType === 'application/pdf' ? 'raw' : 'image',
          format: 'png',
          deliveryType: 'authenticated',
        };
      },
      signedUrl: ({ publicId }) => `https://signed.example/${publicId}`,
      async remove(doc) {
        stored.removed.push(doc.publicId);
      },
    });
  });

  const upload = (auth, documentType, buffer, filename = 'doc.png') =>
    request(app)
      .post('/api/v1/volunteers/me/documents')
      .set('Authorization', auth)
      .field('documentType', documentType)
      .attach('file', buffer, filename);

  it('completes the profile once all required fields are present', async () => {
    const { auth } = await createVolunteer({
      verificationStatus: 'NOT_SUBMITTED',
      status: 'OFFLINE',
      profileCompleted: false,
    });

    const partial = await request(app)
      .patch('/api/v1/volunteers/me')
      .set('Authorization', auth)
      .send({ phone: COMPLETE_PROFILE.phone, city: 'Nashik' });
    const full = await request(app)
      .patch('/api/v1/volunteers/me')
      .set('Authorization', auth)
      .send(COMPLETE_PROFILE);

    expect(partial.body.data.profileCompleted).toBe(false);
    expect(full.body.data).toMatchObject({ profileCompleted: true, profile: COMPLETE_PROFILE });
  });

  it('submits for verification once both required documents are uploaded', async () => {
    const { auth, volunteer } = await createVolunteer({
      verificationStatus: 'NOT_SUBMITTED',
      status: 'OFFLINE',
    });

    const first = await upload(auth, 'ID_PROOF', PNG);
    const second = await upload(auth, 'FIRST_AID_CERTIFICATE', PDF, 'cert.pdf');

    expect(first.status).toBe(201);
    expect(first.body.data.verificationStatus).toBe('NOT_SUBMITTED');
    expect(second.body.data.verificationStatus).toBe('PENDING');
    expect(second.body.data.document).toMatchObject({
      mimeType: 'application/pdf',
      status: 'PENDING',
    });
    expect(second.body.data.document.publicId).toBeUndefined();
    const fresh = await Volunteer.findById(volunteer._id);
    expect(fresh.submittedAt).toBeInstanceOf(Date);
  });

  it('judges files by content, not by extension', async () => {
    const { auth } = await createVolunteer({
      verificationStatus: 'NOT_SUBMITTED',
      status: 'OFFLINE',
    });

    const fake = await upload(auth, 'ID_PROOF', Buffer.from('<script>alert(1)</script>'), 'id.png');

    expect(fake.status).toBe(422);
    expect(fake.body.code).toBe('FILE_UPLOAD_FAILED');
    expect(stored.uploads).toHaveLength(0);
  });

  it('rejects oversized files', async () => {
    const { auth } = await createVolunteer({
      verificationStatus: 'NOT_SUBMITTED',
      status: 'OFFLINE',
    });
    const big = Buffer.concat([PNG, Buffer.alloc(6 * 1024 * 1024)]);

    const res = await upload(auth, 'ID_PROOF', big);

    expect(res.status).toBe(413);
    expect(res.body.code).toBe('FILE_UPLOAD_FAILED');
  });

  it('replacing a document keeps one current copy and deletes the old file', async () => {
    const { auth, volunteer } = await createVolunteer({
      verificationStatus: 'NOT_SUBMITTED',
      status: 'OFFLINE',
    });

    await upload(auth, 'ID_PROOF', PNG);
    await upload(auth, 'ID_PROOF', PNG);

    const docs = await VolunteerDocument.find({ volunteerId: volunteer._id });
    expect(docs.map((d) => d.status).sort()).toEqual(['PENDING', 'REPLACED']);
    await new Promise((r) => setImmediate(r));
    expect(stored.removed).toHaveLength(1);
  });

  it('replacing a required document after approval returns the volunteer to review', async () => {
    const { auth, volunteer } = await createVolunteer();
    await upload(auth, 'FIRST_AID_CERTIFICATE', PDF, 'cert.pdf');
    await Volunteer.updateOne({ _id: volunteer._id }, { verificationStatus: 'APPROVED' });

    const res = await upload(auth, 'ID_PROOF', PNG);

    expect(res.body.data.verificationStatus).toBe('PENDING');
    const fresh = await Volunteer.findById(volunteer._id);
    expect(fresh.status).toBe('OFFLINE');
    expect(fresh.currentLocation).toBeUndefined();
  });

  describe('availability', () => {
    const setStatus = (auth, body) =>
      request(app).patch('/api/v1/volunteers/me/status').set('Authorization', auth).send(body);

    it('requires approval before going ACTIVE', async () => {
      const { auth } = await createVolunteer({ verificationStatus: 'PENDING', status: 'OFFLINE' });

      const res = await setStatus(auth, { status: 'ACTIVE', ...CENTER });

      expect(res.status).toBe(403);
      expect(res.body.code).toBe('VOLUNTEER_NOT_VERIFIED');
    });

    it('requires a fresh location to go ACTIVE', async () => {
      const { auth } = await createVolunteer({ status: 'OFFLINE', location: null });

      const without = await setStatus(auth, { status: 'ACTIVE' });
      const withLocation = await setStatus(auth, { status: 'ACTIVE', ...CENTER, accuracy: 10 });

      expect(without.body.code).toBe('LOCATION_UNAVAILABLE');
      expect(withLocation.status).toBe(200);
      expect(withLocation.body.data).toMatchObject({
        status: 'ACTIVE',
        location: { ...CENTER, isStale: false },
      });
    });

    it('going OFFLINE clears the stored location', async () => {
      const { auth, volunteer } = await createVolunteer();

      const res = await setStatus(auth, { status: 'OFFLINE' });

      expect(res.body.data).toMatchObject({ status: 'OFFLINE', location: null });
      expect((await Volunteer.findById(volunteer._id)).currentLocation).toBeUndefined();
    });

    it('a BUSY volunteer cannot go OFFLINE until the emergency is resolved', async () => {
      const { auth } = await createVolunteer({ status: 'BUSY' });

      const res = await setStatus(auth, { status: 'OFFLINE' });

      expect(res.status).toBe(409);
      expect(res.body.code).toBe('VOLUNTEER_NOT_AVAILABLE');
    });

    it('location updates are accepted only while ACTIVE or BUSY', async () => {
      const offline = await createVolunteer({ status: 'OFFLINE' });
      const active = await createVolunteer();

      const rejected = await request(app)
        .post('/api/v1/volunteers/me/location')
        .set('Authorization', offline.auth)
        .send(CENTER);
      const accepted = await request(app)
        .post('/api/v1/volunteers/me/location')
        .set('Authorization', active.auth)
        .send({ ...CENTER, accuracy: 8 });

      expect(rejected.status).toBe(409);
      expect(accepted.status).toBe(200);
      expect(accepted.body.data.location.accuracy).toBe(8);
    });
  });

  it('volunteer endpoints are closed to other roles', async () => {
    const user = await createAccount();

    const res = await request(app).get('/api/v1/volunteers/me').set('Authorization', user.auth);

    expect(res.status).toBe(403);
  });
});
