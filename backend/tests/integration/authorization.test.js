const request = require('supertest');
const { createApp } = require('../../src/app');
const { ROLES } = require('../../src/config/constants');
const { useTestDatabase } = require('../helpers/db');
const { createAccount } = require('../helpers/factories');

/**
 * Authorization matrix for every endpoint (doc 05 and doc 22).
 *
 * `PUBLIC`  no session needed
 * `SELF`    any signed-in account, even one that must change its password
 *           (so the app can route correctly)
 * otherwise the roles allowed; every other role gets 403.
 *
 * A new route that is not listed here fails the first test, so authorization
 * is decided deliberately rather than by accident.
 */
const PUBLIC = 'PUBLIC';
const SELF = 'SELF';
const ANY = [ROLES.USER, ROLES.VOLUNTEER, ROLES.ADMIN];

const MATRIX = {
  'POST /auth/register': PUBLIC,
  'POST /auth/login': PUBLIC,
  'POST /auth/refresh': PUBLIC,
  'POST /auth/logout': PUBLIC,
  'POST /auth/change-password': SELF,
  'GET /users/me': SELF,
  'PATCH /users/me': SELF,

  'GET /symptoms': [ROLES.USER],
  'POST /symptoms/check': [ROLES.USER],

  'GET /facilities/nearby': ANY,
  'GET /hospitals/nearby': ANY,
  'GET /hospitals/:id': ANY,
  'GET /medical-camps/nearby': ANY,
  'GET /medical-camps/:id': ANY,

  'POST /emergencies': [ROLES.USER],
  'GET /emergencies/my': [ROLES.USER],
  'GET /emergencies/:id': [ROLES.USER],
  'POST /emergencies/:id/cancel': [ROLES.USER],

  'GET /volunteers/me': [ROLES.VOLUNTEER],
  'PATCH /volunteers/me': [ROLES.VOLUNTEER],
  'POST /volunteers/me/documents': [ROLES.VOLUNTEER],
  'GET /volunteers/me/verification': [ROLES.VOLUNTEER],
  'PATCH /volunteers/me/status': [ROLES.VOLUNTEER],
  'POST /volunteers/me/location': [ROLES.VOLUNTEER],
  'GET /volunteers/me/emergencies': [ROLES.VOLUNTEER],
  'GET /volunteers/me/emergencies/:id': [ROLES.VOLUNTEER],
  'GET /volunteers/me/emergencies/:id/route': [ROLES.VOLUNTEER],
  'POST /volunteers/me/emergencies/:id/accept': [ROLES.VOLUNTEER],
  'POST /volunteers/me/emergencies/:id/decline': [ROLES.VOLUNTEER],
  'POST /volunteers/me/emergencies/:id/start': [ROLES.VOLUNTEER],
  'POST /volunteers/me/emergencies/:id/resolve': [ROLES.VOLUNTEER],

  'GET /notifications': ANY,
  'GET /notifications/unread-count': ANY,
  'POST /notifications/read-all': ANY,
  'PATCH /notifications/:id/read': ANY,
  'POST /devices': ANY,
  'DELETE /devices/:token': ANY,

  'GET /admin/dashboard': [ROLES.ADMIN],
  'GET /admin/reports/summary': [ROLES.ADMIN],
  'POST /admin/notices': [ROLES.ADMIN],
  'POST /admin/volunteers': [ROLES.ADMIN],
  'GET /admin/volunteers': [ROLES.ADMIN],
  'GET /admin/volunteers/locations': [ROLES.ADMIN],
  'GET /admin/volunteers/:id': [ROLES.ADMIN],
  'GET /admin/volunteers/:id/documents': [ROLES.ADMIN],
  'POST /admin/volunteers/:id/verify': [ROLES.ADMIN],
  'POST /admin/volunteers/:id/reject': [ROLES.ADMIN],
  'PATCH /admin/volunteers/:id/status': [ROLES.ADMIN],
  'GET /admin/emergencies': [ROLES.ADMIN],
  'GET /admin/emergencies/:id': [ROLES.ADMIN],
  'GET /admin/emergencies/:id/assignments': [ROLES.ADMIN],
  'POST /admin/emergencies/:id/reassign': [ROLES.ADMIN],
  'POST /admin/emergencies/:id/resolve': [ROLES.ADMIN],
  'POST /admin/emergencies/:id/cancel': [ROLES.ADMIN],
  'POST /admin/medical-camps': [ROLES.ADMIN],
  'GET /admin/medical-camps': [ROLES.ADMIN],
  'GET /admin/medical-camps/:id': [ROLES.ADMIN],
  'PATCH /admin/medical-camps/:id': [ROLES.ADMIN],
  'DELETE /admin/medical-camps/:id': [ROLES.ADMIN],
  'GET /admin/users': [ROLES.ADMIN],
  'PATCH /admin/users/:id/status': [ROLES.ADMIN],
};

const MOUNTS = {
  auth: '/auth',
  user: '/users',
  symptom: '/symptoms',
  emergency: '/emergencies',
  volunteer: '/volunteers',
  admin: '/admin',
  notification: '/notifications',
  device: '/devices',
  facility: '',
};

/** Every route the API actually exposes, as "METHOD /path". */
function declaredRoutes() {
  const routes = [];
  for (const [module, prefix] of Object.entries(MOUNTS)) {
    const router = require(`../../src/routes/${module}.routes`);
    for (const layer of router.stack) {
      if (!layer.route) continue;
      const path = layer.route.path === '/' ? '' : layer.route.path;
      for (const method of Object.keys(layer.route.methods)) {
        routes.push(`${method.toUpperCase()} ${prefix}${path}`);
      }
    }
  }
  return routes.sort();
}

const OBJECT_ID = '507f1f77bcf86cd799439011';

function call(app, route, auth) {
  const [method, path] = route.split(' ');
  const url = `/api/v1${path.replace(/:token/, 'device-token-123').replace(/:[a-zA-Z]+/g, OBJECT_ID)}`;
  const req = request(app)[method.toLowerCase()](url);
  return auth ? req.set('Authorization', auth).send({}) : req.send({});
}

describe('Endpoint authorization matrix', () => {
  useTestDatabase();
  const app = createApp();
  const accounts = {};

  beforeEach(async () => {
    for (const role of ANY) accounts[role] = await createAccount({ role });
    accounts.suspended = await createAccount({ accountStatus: 'SUSPENDED' });
    accounts.mustChange = await createAccount({ mustChangePassword: true });
  });

  it('every exposed route has a declared access level', () => {
    expect(declaredRoutes()).toEqual(Object.keys(MATRIX).sort());
  });

  const entries = Object.entries(MATRIX);
  const protectedRoutes = entries.filter(([, access]) => access !== PUBLIC).map(([route]) => route);

  it.each(protectedRoutes)('%s requires a session', async (route) => {
    const res = await call(app, route);

    expect(res.status).toBe(401);
    expect(res.body.code).toBe('AUTH_UNAUTHORIZED');
  });

  const roleChecks = entries
    .filter(([, access]) => Array.isArray(access))
    .flatMap(([route, allowed]) =>
      ANY.filter((role) => !allowed.includes(role)).map((role) => [route, role]),
    );

  it.each(roleChecks)('%s rejects role %s', async (route, role) => {
    const res = await call(app, route, accounts[role].auth);

    expect(res.status).toBe(403);
    expect(res.body.code).toBe('FORBIDDEN');
  });

  it.each(protectedRoutes)('%s rejects a suspended account', async (route) => {
    const res = await call(app, route, accounts.suspended.auth);

    expect(res.status).toBe(403);
    expect(res.body.code).toBe('ACCOUNT_SUSPENDED');
  });

  const passwordGated = entries
    .filter(([, access]) => access !== PUBLIC && access !== SELF)
    .map(([route]) => route);

  it.each(passwordGated)('%s waits for a forced password change', async (route) => {
    const res = await call(app, route, accounts.mustChange.auth);

    expect(res.status).toBe(403);
    expect(res.body.code).toBe('PASSWORD_CHANGE_REQUIRED');
  });

  it.each(entries.filter(([, access]) => access === SELF).map(([route]) => route))(
    '%s stays open during a forced password change',
    async (route) => {
      const res = await call(app, route, accounts.mustChange.auth);

      expect(res.status).not.toBe(403);
    },
  );
});
