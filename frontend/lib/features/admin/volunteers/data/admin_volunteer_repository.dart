import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/utils/json.dart';
import '../../../../shared/enums/volunteer_enums.dart';
import '../../../../shared/models/geo_point.dart';
import '../../../../shared/models/volunteer.dart';

class VolunteerFilter {
  const VolunteerFilter({this.verificationStatus, this.status, this.search = ''});

  final VerificationStatus? verificationStatus;
  final VolunteerStatus? status;
  final String search;

  VolunteerFilter copyWith({String? search}) => VolunteerFilter(
    verificationStatus: verificationStatus,
    status: status,
    search: search ?? this.search,
  );

  @override
  bool operator ==(Object other) =>
      other is VolunteerFilter &&
      other.verificationStatus == verificationStatus &&
      other.status == status &&
      other.search == search;

  @override
  int get hashCode => Object.hash(verificationStatus, status, search);
}

class ReviewDocument {
  const ReviewDocument({required this.document, this.url});

  factory ReviewDocument.fromJson(JsonMap json) =>
      ReviewDocument(document: VolunteerDocumentInfo.fromJson(json), url: asString(json['url']));

  final VolunteerDocumentInfo document;

  /// Short-lived signed URL (P-12).
  final String? url;
}

class VolunteerPin {
  const VolunteerPin({
    required this.volunteerId,
    required this.name,
    required this.status,
    required this.location,
    this.currentEmergencyId,
  });

  factory VolunteerPin.fromJson(JsonMap json) => VolunteerPin(
    volunteerId: asStringOr(json['volunteerId'], ''),
    name: asStringOr(json['name'], ''),
    status: VolunteerStatus.fromApi(json['status']),
    location: VolunteerLocation.tryFromJson(json['location']),
    currentEmergencyId: asString(json['currentEmergencyId']),
  );

  final String volunteerId;
  final String name;
  final VolunteerStatus status;
  final VolunteerLocation? location;
  final String? currentEmergencyId;
}

class AdminVolunteerRepository {
  const AdminVolunteerRepository(this._api);

  final ApiClient _api;

  static const _base = '/admin/volunteers';

  static Volunteer _volunteer(Object? data) => Volunteer.fromJson(asJsonMap(data));

  /// Returns the new volunteer and the one-time temporary password.
  Future<({Volunteer volunteer, String temporaryPassword})> create({
    required String name,
    required String email,
    required String username,
    String? phone,
  }) => _api.post(
    _base,
    body: {
      'name': name,
      'email': email,
      'username': username,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    },
    decode: (data) {
      final json = asJsonMap(data);
      return (
        volunteer: Volunteer.fromJson(asJsonMap(json['volunteer'])),
        temporaryPassword: asStringOr(json['temporaryPassword'], ''),
      );
    },
  );

  Future<Paged<Volunteer>> list(VolunteerFilter filter, {int limit = 50}) => _api.get(
    _base,
    query: {
      'limit': limit,
      'verificationStatus': ?filter.verificationStatus?.apiValue,
      'status': ?filter.status?.apiValue,
      if (filter.search.isNotEmpty) 'search': filter.search,
    },
    decode: (data) => Paged.fromJson(data, Volunteer.fromJson),
  );

  Future<Volunteer> get(String id) => _api.get('$_base/$id', decode: _volunteer);

  Future<List<ReviewDocument>> documents(String id) => _api.get(
    '$_base/$id/documents',
    decode: (data) => asJsonList(data).map(ReviewDocument.fromJson).toList(),
  );

  Future<Volunteer> verify(String id) =>
      _api.post('$_base/$id/verify', body: const <String, Object?>{}, decode: _volunteer);

  Future<Volunteer> reject(String id, String reason) =>
      _api.post('$_base/$id/reject', body: {'reason': reason}, decode: _volunteer);

  Future<Volunteer> setSuspended(String id, {required bool suspended}) => _api.patch(
    '$_base/$id/status',
    body: {'accountStatus': suspended ? 'SUSPENDED' : 'ACTIVE'},
    decode: _volunteer,
  );

  /// Sends a notice to every approved volunteer; returns how many received it.
  Future<int> sendNotice(String message) => _api.post(
    '/admin/notices',
    body: {'message': message},
    decode: (data) => asInt(asJsonMap(data)['recipients']) ?? 0,
  );

  Future<List<VolunteerPin>> locations() => _api.get(
    '$_base/locations',
    decode: (data) => asJsonList(data).map(VolunteerPin.fromJson).toList(),
  );
}

final adminVolunteerRepositoryProvider = Provider<AdminVolunteerRepository>(
  (ref) => AdminVolunteerRepository(ref.watch(apiClientProvider)),
);
