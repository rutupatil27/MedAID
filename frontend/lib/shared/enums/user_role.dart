enum UserRole {
  user('USER'),
  volunteer('VOLUNTEER'),
  admin('ADMIN');

  const UserRole(this.apiValue);

  final String apiValue;

  static UserRole fromApi(Object? value) => UserRole.values.firstWhere(
    (role) => role.apiValue == value,
    orElse: () => throw FormatException('Unknown role: $value'),
  );
}

enum AccountStatus {
  active('ACTIVE'),
  suspended('SUSPENDED');

  const AccountStatus(this.apiValue);

  final String apiValue;

  static AccountStatus fromApi(Object? value) => AccountStatus.values.firstWhere(
    (s) => s.apiValue == value,
    orElse: () => AccountStatus.active,
  );
}
