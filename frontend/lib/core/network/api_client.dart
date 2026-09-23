import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Decodes the `data` field of the standard success envelope.
typedef Decoder<T> = T Function(Object? data);

/// The single HTTP entry point for all repositories (doc 04: centralized API client).
///
/// Unwraps `{ success, message, data }` and converts every failure into an
/// [ApiException] with a language-neutral code.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  static T _cast<T>(Object? data) => data as T;

  Future<T> get<T>(String path, {Map<String, dynamic>? query, required Decoder<T> decode}) =>
      _send(() => _dio.get<Object?>(path, queryParameters: query), decode);

  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    Decoder<T>? decode,
  }) => _send(
    () => _dio.post<Object?>(
      path,
      data: body,
      queryParameters: query,
      options: headers == null ? null : Options(headers: headers),
    ),
    decode ?? _cast<T>,
  );

  Future<T> patch<T>(String path, {Object? body, Decoder<T>? decode}) =>
      _send(() => _dio.patch<Object?>(path, data: body), decode ?? _cast<T>);

  Future<T> delete<T>(String path, {Decoder<T>? decode}) =>
      _send(() => _dio.delete<Object?>(path), decode ?? _cast<T>);

  /// Multipart upload (volunteer documents).
  Future<T> upload<T>(
    String path, {
    required FormData form,
    required Decoder<T> decode,
    ProgressCallback? onSendProgress,
  }) => _send(() => _dio.post<Object?>(path, data: form, onSendProgress: onSendProgress), decode);

  Future<T> _send<T>(Future<Response<Object?>> Function() request, Decoder<T> decode) async {
    try {
      final response = await request();
      final body = response.data;
      if (body is Map<String, dynamic>) {
        if (body['success'] == false) throw _fromEnvelope(body, response.statusCode);
        return decode(body['data']);
      }
      return decode(body);
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  static ApiException mapDioException(DioException error) {
    if (error.error is ApiException) return error.error! as ApiException;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(code: ApiErrorCodes.timeout);
      case DioExceptionType.connectionError:
        return const ApiException(code: ApiErrorCodes.network);
      case DioExceptionType.badResponse:
        final data = error.response?.data;
        final status = error.response?.statusCode;
        if (data is Map<String, dynamic>) return _fromEnvelope(data, status);
        return ApiException(code: _codeForStatus(status), statusCode: status);
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return ApiException(code: ApiErrorCodes.unknown, message: error.message);
    }
  }

  static ApiException _fromEnvelope(Map<String, dynamic> body, int? status) {
    final rawErrors = body['errors'];
    return ApiException(
      code: body['code']?.toString() ?? _codeForStatus(status),
      message: body['message']?.toString(),
      statusCode: status,
      errors: rawErrors is List
          ? rawErrors.whereType<Map<String, dynamic>>().map(FieldError.fromJson).toList()
          : const [],
    );
  }

  static String _codeForStatus(int? status) => switch (status) {
    400 || 422 => ApiErrorCodes.validation,
    401 => ApiErrorCodes.authUnauthorized,
    403 => ApiErrorCodes.forbidden,
    404 => ApiErrorCodes.notFound,
    409 => ApiErrorCodes.conflict,
    429 => ApiErrorCodes.rateLimited,
    _ => ApiErrorCodes.internal,
  };
}
