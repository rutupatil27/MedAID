import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/notifications/presentation/widgets/push_scope.dart';
import 'localization/generated/app_localizations.dart';
import 'localization/locale_provider.dart';
import 'router/app_router.dart';

class MedAidApp extends ConsumerWidget {
  const MedAidApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      locale: locale,
      supportedLocales: AppLocales.supported,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      routerConfig: router,
      // Push taps and foreground pushes need the router and localizations.
      builder: (context, child) => PushScope(child: child ?? const SizedBox.shrink()),
    );
  }
}
