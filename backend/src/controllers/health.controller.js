const { isDatabaseConnected } = require('../config/database');
const { sendSuccess } = require('../utils/apiResponse');

function getHealth(_req, res) {
  const database = isDatabaseConnected() ? 'connected' : 'disconnected';
  return sendSuccess(res, {
    status: database === 'connected' ? 200 : 503,
    message: database === 'connected' ? 'OK' : 'Degraded',
    data: {
      status: database === 'connected' ? 'ok' : 'degraded',
      database,
      uptimeSeconds: Math.round(process.uptime()),
      time: new Date().toISOString(),
    },
  });
}

module.exports = { getHealth };
