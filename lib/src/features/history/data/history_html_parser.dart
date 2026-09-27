import 'dart:convert';
import 'dart:typed_data';

import '../domain/search_entry.dart';
import '../domain/takeout_history.dart';
import '../domain/watch_entry.dart';
import 'export_date.dart';
import 'history_links.dart';

/// Reads a takeout's `history/watch-history.html`.
///
/// Each entry's first link is what was watched, and a channel link after it
/// its uploader; its last line is when. Entries without a link (e.g. "Used
/// Shorts creation tools") and ads are left out. [localOffset] is the
/// device's UTC offset, for ambiguous zone labels; the current one when
/// null.
HistoryFileRead<WatchEntry> parseWatchHistoryHtml(
  Uint8List bytes, {
  Duration? localOffset,
}) => _parseEntries(bytes, localOffset, (entry, time) {
  final (url, text) = entry.links.first;
  final kind = watchKindOf(url);
  if (kind == null) return null;
  final channel = entry.links.skip(1).where((l) => isChannelUrl(l.$1));
  final title = _unescape(text);
  return WatchEntry(
    time: time,
    kind: kind,
    music: entry.music || isMusicUrl(url),
    // A removed or private video is listed by its link.
    title: title == url ? null : title,
    url: url,
    channelTitle: channel.isEmpty ? null : _unescape(channel.first.$2),
    channelUrl: channel.isEmpty ? null : channel.first.$1,
  );
});

/// Reads a takeout's `history/search-history.html`. The query is taken from
/// each entry's link.
HistoryFileRead<SearchEntry> parseSearchHistoryHtml(
  Uint8List bytes, {
  Duration? localOffset,
}) => _parseEntries(bytes, localOffset, (entry, time) {
  final (url, text) = entry.links.first;
  final query = searchQueryOf(url) ?? _unescape(text);
  return SearchEntry(
    time: time,
    music: entry.music || isMusicUrl(url),
    query: query,
  );
});

/// One entry's parts: its links (URL and text), last line and header.
typedef _Entry = ({List<(String, String)> links, String date, bool music});

/// Reads every entry of an activity export, making each with [make] from
/// its parts and time. Entries whose date can't be read are counted as
/// skipped.
HistoryFileRead<T> _parseEntries<T>(
  Uint8List bytes,
  Duration? localOffset,
  T? Function(_Entry entry, DateTime time) make,
) {
  final offset = localOffset ?? DateTime.now().timeZoneOffset;
  final entries = <T>[];
  var skipped = 0;
  // Each entry is decoded on its own: the whole file as one string would
  // take twice its size again.
  for (final (start, end) in _entrySpans(bytes)) {
    final html = utf8.decode(
      Uint8List.sublistView(bytes, start, end),
      allowMalformed: true,
    );
    final entry = _readEntry(html);
    if (entry == null) continue;
    final time = parseExportDate(entry.date, localOffset: offset);
    if (time == null) {
      skipped++;
      continue;
    }
    if (make(entry, time) case final made?) entries.add(made);
  }
  return HistoryFileRead(
    entries: entries,
    skippedRows: skipped,
    unreadable: entries.isEmpty && skipped > 0,
  );
}

final _marker = utf8.encode('<div class="outer-cell');

/// Where each entry's markup starts and ends in [bytes].
Iterable<(int, int)> _entrySpans(Uint8List bytes) sync* {
  var start = _indexOf(bytes, _marker, 0);
  while (start != -1) {
    final next = _indexOf(bytes, _marker, start + _marker.length);
    yield (start, next == -1 ? bytes.length : next);
    start = next;
  }
}

int _indexOf(Uint8List bytes, List<int> pattern, int from) {
  final first = pattern.first;
  final last = bytes.length - pattern.length;
  outer:
  for (var i = from; i <= last; i++) {
    if (bytes[i] != first) continue;
    for (var j = 1; j < pattern.length; j++) {
      if (bytes[i + j] != pattern[j]) continue outer;
    }
    return i;
  }
  return -1;
}

final _header = RegExp(r'mdl-typography--title">([^<]*)');
final _body = RegExp(r'mdl-typography--body-1">(.*?)</div>', dotAll: true);
final _caption = RegExp(r'mdl-typography--caption">(.*?)</div>', dotAll: true);
final _link = RegExp(r'<a href="([^"]*)">([^<]*)</a>');
final _tag = RegExp('<[^>]*>');

/// [html]'s parts, or null for entries that aren't read: those without a
/// link, and ads.
_Entry? _readEntry(String html) {
  final body = _body.firstMatch(html)?[1];
  if (body == null) return null;
  final links = [
    for (final m in _link.allMatches(body)) (_unescape(m[1]!), m[2]!),
  ];
  if (links.isEmpty) return null;
  if (_caption.firstMatch(html)?[1]?.contains('From Google Ads') ?? false) {
    return null;
  }
  final lines = [
    for (final line in body.split('<br>'))
      if (_unescape(line.replaceAll(_tag, '')).trim() case final text
          when text.isNotEmpty)
        text,
  ];
  return (
    links: links,
    date: lines.last,
    music: _header.firstMatch(html)?[1]?.contains('Music') ?? false,
  );
}

final _entity = RegExp(r'&(#x[0-9a-fA-F]+|#\d+|[a-zA-Z]+);');
const _namedEntities = {
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': '\u00a0',
  'emsp': '\u2003',
};

/// [text] with its HTML character references decoded.
String _unescape(String text) {
  if (!text.contains('&')) return text;
  return text.replaceAllMapped(_entity, (m) {
    final name = m[1]!;
    if (name.startsWith('#')) {
      final code = name[1] == 'x'
          ? int.tryParse(name.substring(2), radix: 16)
          : int.tryParse(name.substring(1));
      return code == null ? m[0]! : String.fromCharCode(code);
    }
    return _namedEntities[name] ?? m[0]!;
  });
}
