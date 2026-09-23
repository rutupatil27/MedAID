const { Counter } = require('../models');

/** Atomically increments and returns a named sequence. */
async function nextSequence(name, session = null) {
  const counter = await Counter.findOneAndUpdate(
    { _id: name },
    { $inc: { seq: 1 } },
    { upsert: true, returnDocument: 'after', session },
  );
  return counter.seq;
}

module.exports = { nextSequence };
