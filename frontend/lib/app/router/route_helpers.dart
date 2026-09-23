import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// A route that opens above a role shell's tab bar (on the root navigator).
GoRoute fullScreenRoute(
  GlobalKey<NavigatorState> root,
  String path,
  Widget Function(GoRouterState state) build,
) => GoRoute(path: path, parentNavigatorKey: root, builder: (_, state) => build(state));
