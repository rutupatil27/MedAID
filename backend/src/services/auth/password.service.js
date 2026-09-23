const bcrypt = require('bcryptjs');
const env = require('../../config/env');

// Compared against when an account does not exist, so response time does not
// reveal which identifiers are registered.
const DUMMY_HASH = bcrypt.hashSync('medaid-timing-equalizer', 4);

function hashPassword(password) {
  return bcrypt.hash(password, env.auth.bcryptSaltRounds);
}

function verifyPassword(password, passwordHash) {
  return bcrypt.compare(password, passwordHash ?? DUMMY_HASH);
}

module.exports = { hashPassword, verifyPassword };
