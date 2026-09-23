const {
  createFcmPushProvider,
  createPushProvider,
} = require('../../src/integrations/firebase/pushProvider');

function fakeMessaging(responses = [{ success: true }]) {
  const sent = [];
  return {
    sent,
    async sendEachForMulticast(message) {
      sent.push(message);
      return { responses };
    },
  };
}

describe('FCM push provider', () => {
  const message = {
    title: 'New emergency near you',
    body: 'Respond within 2 minutes.',
    data: { type: 'ASSIGNMENT_NEW', emergencyId: 'e1', assignmentId: 'a1' },
  };

  function send(messaging) {
    const provider = createFcmPushProvider({ serviceAccountPath: '/ignored' }, messaging);
    return provider.send(['token-1'], message);
  }

  it('sends data-only, so the app draws the alert itself', async () => {
    const messaging = fakeMessaging();
    await send(messaging);

    // A `notification` block would make Android draw the alert on its default
    // channel and skip the app entirely when it has been killed, costing the
    // looping ring and the Accept/Decline buttons.
    expect(messaging.sent[0].notification).toBeUndefined();
    expect(messaging.sent[0].data).toEqual({
      type: 'ASSIGNMENT_NEW',
      emergencyId: 'e1',
      assignmentId: 'a1',
      title: message.title,
      body: message.body,
    });
  });

  it('asks Android for high priority, so a dozing or killed app still wakes', async () => {
    const messaging = fakeMessaging();
    await send(messaging);

    expect(messaging.sent[0].android.priority).toBe('high');
  });

  it('keeps the alert text in the APNs payload, which iOS needs to show it', async () => {
    const messaging = fakeMessaging();
    await send(messaging);

    expect(messaging.sent[0].apns.payload.aps.alert).toEqual({
      title: message.title,
      body: message.body,
    });
  });

  it('reports tokens the device no longer holds, so they can be removed', async () => {
    const messaging = fakeMessaging([
      { success: false, error: { code: 'messaging/registration-token-not-registered' } },
    ]);
    const { invalidTokens } = await send(messaging);

    expect(invalidTokens).toEqual(['token-1']);
  });

  it('keeps a token when the failure was not the token itself', async () => {
    const messaging = fakeMessaging([
      { success: false, error: { code: 'messaging/internal-error' } },
    ]);
    const { invalidTokens } = await send(messaging);

    expect(invalidTokens).toEqual([]);
  });

  it('skips push rather than failing when no service account is configured', async () => {
    const provider = createPushProvider({ serviceAccountPath: '' });

    expect(provider.name).toBe('none');
    await expect(provider.send(['token-1'], message)).resolves.toEqual({ invalidTokens: [] });
  });
});
