import 'dart:convert';
import 'dart:typed_data';

import '../domain/search_entry.dart';
import '../domain/takeout_history.dart';
import '../domain/watch_entry.dart';
import 'history_links.dart';

/// Reads a takeout's `history/watch-history.json`.
///
/// Titles come with the export's verb ("Watched …"), which is stripped: the
/// English ones by name, others as the words every title shares. Entries
/// without a link and ads are left out.
HistoryFileRead<WatchEntry> parseWatchHistoryJson(Uint8List bytes) {
  final (:objects, :skipped) = _readObjects(bytes);
  final watches = <({Map<String, Object?> json, String url, WatchKind kind})>[];
  for (final json in objects) {
    final url = json['titleUrl'];
    if (url is! String || _isAd(json)) continue;
    if (watchKindOf(url) case final kind?) {
      watches.add((json: json, url: url, kind: kind));
    }
  }

  final stripVerb = _verbStripper([
    for (final w in watches)
      if (w.json['title'] case final String title when !title.endsWith(w.url))
        title,
  ]);
  final entries = <WatchEntry>[];
  var unreadableTimes = 0;
  for (final (:json, :url, :kind) in watches) {
    final time = _timeOf(json);
    if (time == null) {
      unreadableTimes++;
      continue;
    }
    final title = stripVerb(json['title'] as String? ?? url);
    final channel = _channelOf(json);
    entries.add(
      WatchEntry(
        time: time,
        kind: kind,
        music: _isMusic(json, url),
        // A removed or private video is listed by its link.
        title: title == url || title.isEmpty ? null : title,
        url: url,
        channelTitle: channel?.name,
        channelUrl: channel?.url,
      ),
    );
  }
  return _read(entries, skipped + unreadableTimes);
}

/// Reads a takeout's `history/search-history.json`. The query is taken from
/// each entry's link.
HistoryFileRead<SearchEntry> parseSearchHistoryJson(Uint8List bytes) {
  final (:objects, :skipped) = _readObjects(bytes);
  final entries = <SearchEntry>[];
  var unreadableTimes = 0;
  for (final json in objects) {
    final url = json['titleUrl'];
    if (url is! String) continue;
    final query = searchQueryOf(url);
    if (query == null) continue;
    final time = _timeOf(json);
    if (time == null) {
      unreadableTimes++;
      continue;
    }
    entries.add(
      SearchEntry(time: time, music: _isMusic(json, url), query: query),
    );
  }
  return _read(entries, skipped + unreadableTimes);
}

HistoryFileRead<T> _read<T>(List<T> entries, int skipped) => HistoryFileRead(
  entries: entries,
  skippedRows: skipped,
  unreadable: entries.isEmpty && skipped > 0,
);

/// Each entry of a JSON export, and how many couldn't be decoded. Each is
/// decoded on its own: the whole file at once would build one huge tree.
({List<Map<String, Object?>> objects, int skipped}) _readObjects(
  Uint8List bytes,
) {
  final objects = <Map<String, Object?>>[];
  var skipped = 0;
  for (final (start, end) in _objectSpans(bytes)) {
    try {
      final json = jsonDecode(
        utf8.decode(Uint8List.sublistView(bytes, start, end)),
      );
      if (json is Map<String, Object?>) {
        objects.add(json);
      } else {
        skipped++;
      }
    } on FormatException {
      skipped++;
    }
  }
  return (objects: objects, skipped: skipped);
}

const _openBrace = 0x7b, _closeBrace = 0x7d, _openBracket = 0x5b;
const _closeBracket = 0x5d, _quote = 0x22, _backslash = 0x5c;

/// Where each object in the top-level array of [bytes] starts and ends.
Iterable<(int, int)> _objectSpans(Uint8List bytes) sync* {
  var depth = 0;
  var start = -1;
  var inString = false;
  var escaped = false;
  for (var i = 0; i < bytes.length; i++) {
    final byte = bytes[i];
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (byte == _backslash) {
        escaped = true;
      } else if (byte == _quote) {
        inString = false;
      }
      continue;
    }
    switch (byte) {
      case _quote:
        inString = true;
      case _openBrace || _openBracket:
        if (depth == 1 && byte == _openBrace) start = i;
        depth++;
      case _closeBrace || _closeBracket:
        depth--;
        if (depth == 1 && byte == _closeBrace && start >= 0) {
          yield (start, i + 1);
          start = -1;
        }
    }
  }
}

DateTime? _timeOf(Map<String, Object?> json) => switch (json['time']) {
  final String time => DateTime.tryParse(time)?.toUtc(),
  _ => null,
};

bool _isMusic(Map<String, Object?> json, String url) =>
    isMusicUrl(url) ||
    ((json['header'] as String?)?.contains('Music') ?? false);

bool _isAd(Map<String, Object?> json) => switch (json['details']) {
  final List<Object?> details => details.any(
    (d) => d is Map && d['name'] == 'From Google Ads',
  ),
  _ => false,
};

({String name, String url})? _channelOf(Map<String, Object?> json) {
  if (json['subtitles'] case final List<Object?> subtitles) {
    for (final subtitle in subtitles) {
      if (subtitle case {
        'name': final String name,
        'url': final String url,
      } when isChannelUrl(url)) {
        return (name: name, url: url);
      }
    }
  }
  return null;
}

const _englishVerbs = ['Watched ', 'Viewed ', 'Played '];

/// What takes the export's verb off a title, worked out from [titles]: the
/// English verbs, or else the words at the start or end every title shares.
String Function(String) _verbStripper(List<String> titles) {
  if (titles.any((t) => _englishVerbs.any(t.startsWith)) || titles.length < 2) {
    return (title) {
      for (final verb in _englishVerbs) {
        if (title.startsWith(verb)) return title.substring(verb.length);
      }
      return title;
    };
  }
  var prefix = titles.first;
  var suffix = titles.first;
  for (final title in titles.skip(1)) {
    prefix = _sharedPrefix(prefix, title);
    suffix = _sharedSuffix(suffix, title);
  }
  // Only whole words: titles may happen to share their first letters too.
  prefix = prefix.substring(0, prefix.lastIndexOf(' ') + 1);
  final wordStart = suffix.indexOf(' ');
  suffix = wordStart == -1 ? '' : suffix.substring(wordStart);
  return (title) {
    var stripped = title;
    if (prefix.isNotEmpty && stripped.startsWith(prefix)) {
      stripped = stripped.substring(prefix.length);
    }
    if (suffix.isNotEmpty && stripped.endsWith(suffix)) {
      stripped = stripped.substring(0, stripped.length - suffix.length);
    }
    return stripped.trim();
  };
}

String _sharedPrefix(String a, String b) {
  var i = 0;
  while (i < a.length && i < b.length && a.codeUnitAt(i) == b.codeUnitAt(i)) {
    i++;
  }
  return a.substring(0, i);
}

String _sharedSuffix(String a, String b) {
  var i = 0;
  while (i < a.length &&
      i < b.length &&
      a.codeUnitAt(a.length - 1 - i) == b.codeUnitAt(b.length - 1 - i)) {
    i++;
  }
  return a.substring(a.length - i);
}
