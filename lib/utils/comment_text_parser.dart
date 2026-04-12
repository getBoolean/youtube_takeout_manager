import 'dart:convert';

/// Parses the JSON-encoded comment/live chat text field from Google Takeout CSVs.
///
/// The field contains a comma-separated sequence of JSON objects like:
/// `{"text":"@user","mention":{...}},{"text":" the actual comment"}`
///
/// Returns the concatenated plain text from all segments.
String parseCommentText(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';

  try {
    final jsonArray = jsonDecode('[$trimmed]') as List;
    return jsonArray
        .map((segment) => (segment as Map<String, dynamic>)['text'] as String?)
        .where((text) => text != null)
        .join();
  } catch (_) {
    // If JSON parsing fails, return the raw text as-is
    return raw;
  }
}
