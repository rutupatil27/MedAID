const request = require('supertest');
const { hashPassword } = require('../../src/services/auth/password.service');
const { issueTokens } = require('../../src/services/auth/token.service');
const { User } = require('../../src/models');

let sequence = 0;

/** Creates an account directly in the database and returns it with tokens. */
async function createAccount(overrides = {}) {
  sequence += 1;
  const password = overrides.password ?? 'Passw0rd!';
  const user = await User.create({
    name: overrides.name ?? `Person ${sequence}`,
    email: overrides.email ?? `person${sequence}@example.com`,
    username: overrides.username ?? `person${sequence}`,
    role: overrides.role ?? 'USER',
    accountStatus: overrides.accountStatus ?? 'ACTIVE',
    mustChangePassword: overrides.mustChangePassword ?? false,
    preferredLanguage: overrides.preferredLanguage ?? 'en',
    passwordHash: await hashPassword(password),
  });
  const tokens = await issueTokens(user);
  return { user, password, ...tokens, auth: `Bearer ${tokens.accessToken}` };
}

/** Registers through the API. */
function registerViaApi(app, body = {}) {
  sequence += 1;
  return request(app)
    .post('/api/v1/auth/register')
    .send({
      name: 'Asha Patil',
      email: `asha${sequence}@example.com`,
      username: `asha${sequence}`,
      password: 'Secure123',
      ...body,
    });
}

module.exports = { createAccount, registerViaApi };
