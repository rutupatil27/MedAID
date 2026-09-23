import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/network_providers.dart';
import 'push_service.dart';

/// Registers this device for push after sign-in (`POST /devices`) and removes
/// it before sign-out (`DELETE /devices/:token`), so a shared phone never
/// receives the previous account's alerts. Best effort: failures are retried
/// on the next sign-in or token refresh and never block the session.
class DeviceRegistration {
  DeviceRegistration(this._api, this._push);

  final ApiClient _api;
  final PushService _push;
  String? _token;
  StreamSubscription<String>? _refresh;

  static const _unregisterTimeout = Duration(seconds: 5);

  Future<void> register() async {
    if (!_push.isEnabled) return;
    try {
      await _push.requestPermission();
      final token = await _push.getToken();
      if (token != null) await _send(token);
      _refresh ??= _push.onTokenRefresh.listen((token) => _send(token).ignore());
    } catch (_) {
      // Push stays off for this session; in-app notifications still work.
    }
  }

  Future<void> _send(String token) async {
    await _api.post<void>('/devices', body: {'token': token, 'platform': _push.platform});
    _token = token;
  }

  Future<void> unregister() async {
    // Not awaited: cancelling stops delivery at once, and the future it
    // returns belongs to the root zone.
    _refresh?.cancel().ignore();
    _refresh = null;
    final token = _token;
    _token = null;
    if (token == null) return;
    try {
      await _api.delete<void>('/devices/${Uri.encodeComponent(token)}').timeout(_unregisterTimeout);
    } catch (_) {
      // Signing out must always succeed; the server prunes dead tokens anyway.
    }
  }
}

// Sign-out removes the device explicitly (see AuthController.logout); there is
// no point trying it while the app is shutting down.
final deviceRegistrationProvider = Provider<DeviceRegistration>(
  (ref) => DeviceRegistration(ref.watch(apiClientProvider), ref.watch(pushServiceProvider)),
);
