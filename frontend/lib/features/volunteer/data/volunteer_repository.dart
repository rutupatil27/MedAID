import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/files/document_picker.dart';
import '../../../core/location/location_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/utils/json.dart';
import '../../../shared/enums/volunteer_enums.dart';
import '../../../shared/models/emergency.dart';
import '../../../shared/models/geo_point.dart';
import '../../../shared/models/response_route.dart';
import '../../../shared/models/volunteer.dart';

enum EmergencyScope { active, history }

/// Volunteer self-service API (`/volunteers/me/...`).
class VolunteerRepository {
  const VolunteerRepository(this._api);

  final ApiClient _api;

  static const _base = '/volunteers/me';

  static Volunteer _volunteer(Object? data) => Volunteer.fromJson(asJsonMap(data));
  static Emergency _emergency(Object? data) => Emergency.fromJson(asJsonMap(data));

  Future<Volunteer> me() => _api.get(_base, decode: _volunteer);

  Future<Volunteer> updateProfile(Map<String, Object?> changes) =>
      _api.patch(_base, body: changes, decode: _volunteer);

  /// Returns the verification status after the upload.
  Future<VerificationStatus> uploadDocument(
    DocumentType type,
    PickedDocument document, {
    void Function(double progress)? onProgress,
  }) => _api.upload(
    '$_base/documents',
    form: FormData.fromMap({
      'documentType': type.apiValue,
      'file': MultipartFile.fromBytes(document.bytes, filename: document.name),
    }),
    onSendProgress: onProgress == null
        ? null
        : (sent, total) => onProgress(total <= 0 ? 0 : sent / total),
    decode: (data) => VerificationStatus.fromApi(asJsonMap(data)['verificationStatus']),
  );

  Future<Volunteer> setStatus(VolunteerStatus status, {LocationFix? fix}) => _api.patch(
    '$_base/status',
    body: {
      'status': status.apiValue,
      if (fix != null) ...fix.point.toJson(),
      if (fix?.accuracyMeters != null) 'accuracy': fix!.accuracyMeters,
    },
    decode: _volunteer,
  );

  Future<void> updateLocation(LocationFix fix) => _api.post<void>(
    '$_base/location',
    body: {...fix.point.toJson(), 'accuracy': ?fix.accuracyMeters},
  );

  Future<Paged<Emergency>> emergencies(EmergencyScope scope, {int limit = 50}) => _api.get(
    '$_base/emergencies',
    query: {'scope': scope == EmergencyScope.active ? 'ACTIVE' : 'HISTORY', 'limit': limit},
    decode: (data) => Paged.fromJson(data, Emergency.fromJson),
  );

  Future<Emergency> emergency(String id) => _api.get('$_base/emergencies/$id', decode: _emergency);

  /// Route/ETA from the stored volunteer location (P-20: routing stays server-side).
  Future<ResponseRoute> route(String id) =>
      _api.get('$_base/emergencies/$id/route', decode: ResponseRoute.fromJson);

  Future<Emergency> accept(String id) =>
      _api.post('$_base/emergencies/$id/accept', decode: _emergency);

  Future<Emergency> decline(String id, {String? reason}) =>
      _api.post('$_base/emergencies/$id/decline', body: {'reason': ?reason}, decode: _emergency);

  Future<Emergency> start(String id) =>
      _api.post('$_base/emergencies/$id/start', decode: _emergency);

  Future<Emergency> resolve(String id, String note) => _api.post(
    '$_base/emergencies/$id/resolve',
    body: {'resolutionNote': note},
    decode: _emergency,
  );
}

final volunteerRepositoryProvider = Provider<VolunteerRepository>(
  (ref) => VolunteerRepository(ref.watch(apiClientProvider)),
);
