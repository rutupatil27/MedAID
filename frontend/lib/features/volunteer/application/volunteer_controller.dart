import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/files/document_picker.dart';
import '../../../core/location/location_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/enums/volunteer_enums.dart';
import '../../../shared/models/volunteer.dart';
import '../data/volunteer_repository.dart';

/// The signed-in volunteer: profile, documents, verification and availability.
class VolunteerController extends AsyncNotifier<Volunteer> {
  VolunteerRepository get _repository => ref.read(volunteerRepositoryProvider);

  @override
  Future<Volunteer> build() => ref.watch(volunteerRepositoryProvider).me();

  Future<void> refresh() async {
    final latest = await _repository.me();
    if (ref.mounted) state = AsyncData(latest);
  }

  Future<void> updateProfile(Map<String, Object?> changes) async {
    final updated = await _repository.updateProfile(changes);
    if (ref.mounted) state = AsyncData(updated);
  }

  /// Uploads [document] as [type] and refreshes the verification state.
  Future<void> uploadDocument(DocumentType type, PickedDocument document) async {
    if (document.bytes.length > AppConfig.maxDocumentBytes) {
      throw const ApiException(code: ApiErrorCodes.fileTooLarge);
    }
    final progress = ref.read(documentUploadProgressProvider.notifier);
    progress.update(type, 0);
    try {
      await _repository.uploadDocument(
        type,
        document,
        onProgress: (value) => progress.update(type, value),
      );
      await refresh();
    } finally {
      progress.clear(type);
    }
  }

  /// Active needs verification and a current location (doc 07).
  Future<void> setAvailable(bool available) async {
    Volunteer updated;
    if (available) {
      final location = ref.read(locationServiceProvider);
      await location.requestAccess();
      final fix = await location.currentFix(timeout: AppConfig.sosLocationTimeout);
      if (fix == null) throw const ApiException(code: ApiErrorCodes.locationUnavailable);
      updated = await _repository.setStatus(VolunteerStatus.active, fix: fix);
    } else {
      updated = await _repository.setStatus(VolunteerStatus.offline);
    }
    if (ref.mounted) state = AsyncData(updated);
  }
}

final volunteerProvider = AsyncNotifierProvider<VolunteerController, Volunteer>(
  VolunteerController.new,
);

/// Upload progress (0..1) per document type while an upload is running.
class DocumentUploadProgress extends Notifier<Map<DocumentType, double>> {
  @override
  Map<DocumentType, double> build() => const {};

  void update(DocumentType type, double value) => state = {...state, type: value};

  void clear(DocumentType type) => state = {...state}..remove(type);
}

final documentUploadProgressProvider =
    NotifierProvider<DocumentUploadProgress, Map<DocumentType, double>>(DocumentUploadProgress.new);
