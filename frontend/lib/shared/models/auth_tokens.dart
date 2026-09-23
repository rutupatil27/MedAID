import '../../core/utils/json.dart';

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(JsonMap json) => AuthTokens(
    accessToken: asStringOr(json['accessToken'], ''),
    refreshToken: asStringOr(json['refreshToken'], ''),
  );

  final String accessToken;
  final String refreshToken;

  bool get isValid => accessToken.isNotEmpty && refreshToken.isNotEmpty;
}
