/** Registers every model so indexes are built at startup. */
module.exports = {
  User: require('./user.model'),
  Volunteer: require('./volunteer.model'),
  VolunteerDocument: require('./volunteerDocument.model'),
  Emergency: require('./emergency.model'),
  EmergencyAssignment: require('./emergencyAssignment.model'),
  MedicalCamp: require('./medicalCamp.model'),
  Hospital: require('./hospital.model'),
  Notification: require('./notification.model'),
  RefreshToken: require('./refreshToken.model'),
  DeviceToken: require('./deviceToken.model'),
  Counter: require('./counter.model'),
};
