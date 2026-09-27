/// File formats comments and live chats can be exported as.
enum ExportFormat {
  csv(extension: 'csv', mimeType: 'text/csv'),
  json(extension: 'json', mimeType: 'application/json');

  const ExportFormat({required this.extension, required this.mimeType});

  /// File extension, without the dot.
  final String extension;

  /// MIME type the file is saved with.
  final String mimeType;
}
