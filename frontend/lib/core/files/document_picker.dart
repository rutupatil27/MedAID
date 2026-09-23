import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PickedDocument {
  const PickedDocument({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// Lets the user choose a verification document (PDF or image).
abstract interface class DocumentPicker {
  /// Null when the user cancels.
  Future<PickedDocument?> pick();
}

class FilePickerDocumentPicker implements DocumentPicker {
  const FilePickerDocumentPicker();

  static const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

  @override
  Future<PickedDocument?> pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    if (file == null) return null;
    return PickedDocument(name: file.name, bytes: await file.readAsBytes());
  }
}

final documentPickerProvider = Provider<DocumentPicker>((ref) => const FilePickerDocumentPicker());
