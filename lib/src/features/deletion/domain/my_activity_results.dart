import 'dart:convert';

/// The results a My Activity script run copies to the clipboard, as read
/// back from what the user pasted.
sealed class ParsedMyActivityResults {
  const ParsedMyActivityResults();
}

final class MyActivityResults extends ParsedMyActivityResults {
  final Set<String> deleted;
  final List<({String id, String error})> failed;

  const MyActivityResults({required this.deleted, required this.failed});

  Map<String, String> get errorsById => {for (final f in failed) f.id: f.error};
}

/// Text that isn't the script's results, with why.
final class MalformedMyActivityResults extends ParsedMyActivityResults {
  final String error;

  const MalformedMyActivityResults(this.error);
}

/// Reads [text], the JSON a My Activity script run copies:
/// `{"succeeded": [id, ...], "failed": [{"id": id, "error": text}, ...]}`.
ParsedMyActivityResults parseMyActivityResults(String text) {
  try {
    final map = jsonDecode(text) as Map<String, dynamic>;
    final deleted = (map['succeeded'] as List).cast<String>().toSet();
    final failed = [
      for (final f in map['failed'] as List)
        (
          id: (f as Map<String, dynamic>)['id'] as String,
          error: f['error'] as String,
        ),
    ];
    return MyActivityResults(deleted: deleted, failed: failed);
  } catch (e) {
    return MalformedMyActivityResults('$e');
  }
}
