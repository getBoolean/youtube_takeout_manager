import 'dart:convert';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/export_format.dart';

part 'export_file_repository.g.dart';

@Riverpod(keepAlive: true)
ExportFileRepository exportFileRepository(Ref ref) => ExportFileRepository();

/// Saves exported files where the user picks, or to downloads on web.
class ExportFileRepository {
  /// Saves [content] as [filename] in [format]. Returns `true` if the file
  /// was saved, `false` if the user cancelled.
  Future<bool> save(
    String content,
    String filename,
    ExportFormat format,
  ) async {
    final bytes = Uint8List.fromList(utf8.encode(content));

    if (kIsWeb) {
      final result = await FileSaver.instance.saveFile(
        name: filename,
        bytes: bytes,
        fileExtension: format.extension,
        mimeType: MimeType.custom,
        customMimeType: format.mimeType,
      );
      return result.isNotEmpty;
    }

    final result = await FileSaver.instance.saveAs(
      name: filename,
      bytes: bytes,
      fileExtension: format.extension,
      mimeType: MimeType.custom,
      customMimeType: format.mimeType,
    );
    return result != null;
  }
}
