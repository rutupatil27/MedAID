import 'dart:async';

import 'package:medaid/core/notifications/local_notifier.dart';

class ShownAlert {
  const ShownAlert({
    required this.id,
    required this.title,
    required this.body,
    this.payload,
    this.actions = const [],
    this.ongoing = false,
  });

  final int id;
  final String title;
  final String body;
  final String? payload;
  final List<AlertAction> actions;
  final bool ongoing;
}

/// Records system notifications instead of showing them.
class FakeLocalNotifier implements LocalNotifier {
  final shown = <ShownAlert>[];
  final cancelled = <int>[];
  final responses = StreamController<AlertResponse>.broadcast();
  bool permissionGranted = true;
  int permissionRequests = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> showAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
    List<AlertAction> actions = const [],
    bool ongoing = false,
  }) async {
    shown.add(
      ShownAlert(
        id: id,
        title: title,
        body: body,
        payload: payload,
        actions: actions,
        ongoing: ongoing,
      ),
    );
  }

  @override
  Future<void> cancel(int id) async => cancelled.add(id);

  @override
  Stream<AlertResponse> get onOpened => responses.stream;
}
