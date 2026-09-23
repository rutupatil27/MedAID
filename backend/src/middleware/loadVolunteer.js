const AppError = require('../utils/AppError');
const volunteerRepository = require('../repositories/volunteer.repository');

/** Attaches the signed-in volunteer's record as `req.volunteer`. */
async function loadVolunteer(req, _res, next) {
  const volunteer = await volunteerRepository.findByUserId(req.user.id);
  if (!volunteer) throw AppError.notFound('Volunteer profile');
  req.volunteer = volunteer;
  next();
}

module.exports = { loadVolunteer };
