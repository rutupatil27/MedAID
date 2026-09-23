import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/locale_provider.dart';
import '../constants/app_config.dart';
import '../storage/token_storage.dart';
import 'api_client.dart';
import 'auth_interceptor.dart';

/// Emits when the stored session can no longer be refreshed. The auth
/// controller listens and returns the app to the login screen. This breaks the
/// dio -> auth -> repository -> dio dependency cycle.
final sessionExpiredEventsProvider = Provider<StreamController<void>>((ref) {
  final controller = StreamController<void>.broadcast();
  ref.onDispose(controller.close);
  return controller;
});

/// Configured Dio instance. Interceptors are attached here only.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      sendTimeout: AppConfig.sendTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: const {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.addAll([
    // Lets the backend return localized content (e.g. symptom guidance).
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Accept-Language'] = ref.read(localeProvider).languageCode;
        handler.next(options);
      },
    ),
    AuthInterceptor(
      dio: dio,
      storage: ref.read(tokenStorageProvider),
      onSessionExpired: () => ref.read(sessionExpiredEventsProvider).add(null),
    ),
  ]);

  ref.onDispose(dio.close);
  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(dioProvider)));
