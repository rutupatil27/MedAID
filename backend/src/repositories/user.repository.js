const { User } = require('../models');

const escapeRegex = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

function findById(id, { withPassword = false } = {}) {
  const query = User.findById(id);
  return withPassword ? query.select('+passwordHash') : query;
}

/** Login accepts either email or username (FR-01). */
function findByIdentifier(identifier, { withPassword = false } = {}) {
  const value = identifier.trim().toLowerCase();
  const query = User.findOne({ $or: [{ email: value }, { username: value }] });
  return withPassword ? query.select('+passwordHash') : query;
}

async function findTakenFields({ email, username }) {
  const existing = await User.find(
    { $or: [{ email: email.toLowerCase() }, { username: username.toLowerCase() }] },
    { email: 1, username: 1 },
  ).lean();
  const taken = [];
  if (existing.some((u) => u.email === email.toLowerCase())) taken.push('email');
  if (existing.some((u) => u.username === username.toLowerCase())) taken.push('username');
  return taken;
}

function create(data, session = null) {
  return new User(data).save({ session });
}

function updateById(id, update, options = {}) {
  return User.findByIdAndUpdate(id, update, {
    returnDocument: 'after',
    runValidators: true,
    ...options,
  });
}

async function list({ role, accountStatus, search, page, limit }) {
  const filter = {};
  if (role) filter.role = role;
  if (accountStatus) filter.accountStatus = accountStatus;
  if (search) {
    const pattern = new RegExp(escapeRegex(search), 'i');
    filter.$or = [{ name: pattern }, { email: pattern }, { username: pattern }];
  }
  const [items, total] = await Promise.all([
    User.find(filter)
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit),
    User.countDocuments(filter),
  ]);
  return { items, total };
}

/** Just what notification delivery needs: role and language. */
function findRecipients(ids) {
  return User.find({ _id: { $in: ids } }, { role: 1, preferredLanguage: 1 });
}

/** IDs among `ids` whose accounts are ACTIVE and have `role`. */
async function filterActive(ids, role) {
  const users = await User.find(
    { _id: { $in: ids }, role, accountStatus: 'ACTIVE' },
    { _id: 1 },
  ).lean();
  return users.map((u) => u._id);
}

function findAdmins() {
  return User.find({ role: 'ADMIN', accountStatus: 'ACTIVE' });
}

function countByRole() {
  return User.aggregate([{ $group: { _id: '$role', count: { $sum: 1 } } }]);
}

module.exports = {
  findById,
  findByIdentifier,
  findTakenFields,
  create,
  updateById,
  list,
  findRecipients,
  filterActive,
  findAdmins,
  countByRole,
};
