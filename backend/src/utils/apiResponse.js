/** Standard success envelope (doc 09). */
function sendSuccess(res, { status = 200, message = 'OK', data = null } = {}) {
  return res.status(status).json({ success: true, message, data });
}

/** Standard error envelope (doc 09). */
function sendError(res, { status, code, message, errors = [] }) {
  return res.status(status).json({ success: false, message, code, errors });
}

module.exports = { sendSuccess, sendError };
