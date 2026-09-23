/// A volunteer document to show in the viewer: what it is, and a short-lived
/// signed URL to fetch it with. Passed between screens, never stored.
class DocumentPreview {
  const DocumentPreview({required this.title, required this.url, this.mimeType});

  final String title;
  final String url;
  final String? mimeType;

  bool get isImage => mimeType?.startsWith('image/') ?? false;
}
