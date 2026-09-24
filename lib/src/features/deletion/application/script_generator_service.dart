import 'dart:convert';

import 'package:flutter/services.dart';

/// Generates a self-contained JavaScript snippet that deletes YouTube comments
/// and live chat messages via Google's My Activity internal RPC endpoint.
///
/// The user pastes this script into the browser console on
/// https://myactivity.google.com/page?hl=en&page=youtube_comments
/// and it runs without YouTube Data API quota limits.
///
/// Both comments and live chats use the same `youtube_comments` activity type.
class ScriptGeneratorService {
  static const _assetPath = 'assets/scripts/delete_comments.js';

  /// Generates a JS script that deletes the given IDs (comments and/or live
  /// chats) and copies a JSON results summary to the clipboard when complete.
  Future<String> generateDeletionScript(Set<String> ids) async {
    final template = await rootBundle.loadString(_assetPath);
    final idsJson = jsonEncode(ids.toList());

    return template
        .replaceFirst('__COMMENT_IDS__', idsJson)
        .replaceFirst('__COMMENT_COUNT__', '${ids.length}');
  }
}
