const { authorize } = require('../../src/middleware/authorize');

function run(middleware, user) {
  let result;
  middleware({ user }, {}, (err) => {
    result = err;
  });
  return result;
}

describe('authorize middleware', () => {
  it('allows listed roles', () => {
    expect(run(authorize('ADMIN'), { role: 'ADMIN' })).toBeUndefined();
  });

  it('forbids other roles', () => {
    expect(run(authorize('ADMIN'), { role: 'VOLUNTEER' })).toMatchObject({
      code: 'FORBIDDEN',
      status: 403,
    });
  });

  it('requires authentication', () => {
    expect(run(authorize('USER'), undefined)).toMatchObject({ code: 'AUTH_UNAUTHORIZED' });
  });

  it('blocks accounts that must change their password', () => {
    expect(
      run(authorize('VOLUNTEER'), { role: 'VOLUNTEER', mustChangePassword: true }),
    ).toMatchObject({ code: 'PASSWORD_CHANGE_REQUIRED' });
  });
});
