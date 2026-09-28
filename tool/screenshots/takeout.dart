// Builds the made-up YouTube Takeout in takeout.json into what the
// screenshots need: the zip Google would export, the video details and
// channel pictures to seed the app's cache with (what sign-in would fetch),
// and what each picture should look like. None of it is real.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

typedef Avatar = ({
  String channelId,
  String text,
  bool monogram,
  List<String> colors,
});

typedef Thumbnail = ({
  String videoId,
  String? caption,
  String emoji,
  List<String> colors,
  bool live,
  int layout,
});

typedef FakeTakeout = ({
  Uint8List zip,
  Map<String, String> seed,
  List<Avatar> avatars,
  List<Thumbnail> thumbnails,
});

/// The zip's name, as Google would name an export made on 2026-09-27.
const takeoutFileName = 'takeout-20260927T180000Z-001.zip';

const _source = 'tool/screenshots/takeout.json';

typedef _Json = Map<String, dynamic>;

List<_Json> _list(Object? value) => (value as List).cast<_Json>();
List<String> _colors(_Json picture) => (picture['colors'] as List).cast();

String _quote(Object? value) {
  final s = '${value ?? ''}';
  return RegExp(r'[",\n]').hasMatch(s) ? '"${s.replaceAll('"', '""')}"' : s;
}

String _csv(List<String> header, Iterable<List<Object?>> rows) =>
    '${[header, ...rows].map((r) => r.map(_quote).join(',')).join('\n')}\n';

/// Takeout's text columns hold JSON segments, mentions included.
String _segments(String text, [_Json? mention]) => [
  if (mention != null) ...[
    {
      'text': mention['name'],
      'mention': {'externalChannelId': mention['channelId']},
    },
    {'text': ' $text'},
  ] else
    {'text': text},
].map(jsonEncode).join(',');

FakeTakeout loadTakeout() {
  final json = jsonDecode(File(_source).readAsStringSync()) as _Json;
  final account = json['account'] as _Json;
  final ownId = account['channelId'] as String;
  final channels = _list(json['channels']);
  final videos = {
    for (final channel in channels)
      for (final video in _list(channel['videos']))
        video['id'] as String: (video: video, channel: channel),
  };

  final archive = Archive();
  void write(String path, String content) => archive.addFile(
    ArchiveFile.string('Takeout/YouTube and YouTube Music/$path', content),
  );

  write(
    'comments/comments.csv',
    _csv(
      [
        'Comment ID',
        'Channel ID',
        'Comment Create Timestamp',
        'Price',
        'Parent Comment ID',
        'Post ID',
        'Video ID',
        'Comment Text',
        'Top-Level Comment ID',
      ],
      [
        for (final c in _list(json['comments']))
          [
            c['id'],
            ownId,
            c['createdAt'],
            '0',
            c['parentId'],
            '',
            c['videoId'],
            _segments(c['text'] as String, c['mention'] as _Json?),
            c['parentId'] ?? c['id'],
          ],
      ],
    ),
  );
  write(
    'live chats/live chats.csv',
    _csv(
      [
        'Live Chat ID',
        'Channel ID',
        'Live Chat Create Timestamp',
        'Price',
        'Currency code',
        'Video ID',
        'Live Chat Text',
      ],
      [
        for (final l in _list(json['liveChats']))
          [
            l['id'],
            ownId,
            l['createdAt'],
            l['price'] ?? 0,
            l['currency'],
            l['videoId'],
            _segments(l['text'] as String),
          ],
      ],
    ),
  );
  write(
    'channels/channel.csv',
    _csv(
      [
        'Channel ID',
        'Channel Description (Original)',
        'Channel Tag 1',
        'Channel Title (Original)',
        'Channel Visibility',
      ],
      [
        [ownId, account['description'], '', account['title'], 'Public'],
      ],
    ),
  );
  write(
    'channels/channel URL configs.csv',
    _csv(
      ['Channel ID', 'Channel Vanity URL 1 Name'],
      [
        [ownId, account['handle']],
      ],
    ),
  );
  write(
    'subscriptions/subscriptions.csv',
    _csv(
      ['Channel Id', 'Channel Url', 'Channel Title'],
      [
        for (final c in channels)
          if (c['subscribed'] == true)
            [c['id'], 'http://www.youtube.com/channel/${c['id']}', c['title']],
      ],
    ),
  );

  const indented = JsonEncoder.withIndent('  ');
  write(
    'history/watch-history.json',
    indented.convert([
      for (final entry in _list(json['watchHistory']))
        if (videos[entry['videoId']] case (:final video, :final channel))
          {
            'header': 'YouTube',
            'title': 'Watched ${video['title']}',
            'titleUrl': 'https://www.youtube.com/watch?v=${video['id']}',
            'subtitles': [
              {
                'name': channel['title'],
                'url': 'https://www.youtube.com/channel/${channel['id']}',
              },
            ],
            'time': entry['time'],
            'products': ['YouTube'],
            'activityControls': ['YouTube watch history'],
          },
    ]),
  );
  write(
    'history/search-history.json',
    indented.convert([
      for (final entry in _list(json['searchHistory']))
        {
          'header': 'YouTube',
          'title': 'Searched for ${entry['query']}',
          'titleUrl':
              'https://www.youtube.com/results?search_query='
              '${(entry['query'] as String).replaceAll(' ', '+')}',
          'time': entry['time'],
          'products': ['YouTube'],
          'activityControls': ['YouTube search history'],
        },
    ]),
  );

  final videoCache = {
    for (final (:video, :channel) in videos.values)
      video['id']: {
        'videoId': video['id'],
        'channelId': channel['id'],
        'channelTitle': channel['title'],
        'title': video['title'],
        'description': null,
        'thumbnailUrl': 'https://i.ytimg.com/vi/${video['id']}/mqdefault.jpg',
        'publishedAt': null,
      },
  };
  final pictureUrls = {
    for (final id in [ownId, for (final c in channels) c['id']])
      id: 'https://yt3.ggpht.com/ytc/$id=s176-c-k-c0x00ffffff-no-rj',
  };

  final ownPicture = account['picture'] as _Json;
  return (
    zip: ZipEncoder().encodeBytes(archive),
    seed: {
      'cached_video_metadata': jsonEncode(videoCache),
      'cached_channel_thumbnails': jsonEncode(pictureUrls),
    },
    avatars: [
      (
        channelId: ownId,
        text: ownPicture['monogram'] as String,
        monogram: true,
        colors: _colors(ownPicture),
      ),
      for (final c in channels)
        (
          channelId: c['id'] as String,
          text: (c['picture'] as _Json)['emoji'] as String,
          monogram: false,
          colors: _colors(c['picture'] as _Json),
        ),
    ],
    thumbnails: [
      // Thumbnails take turns at the four layouts.
      for (final (i, (:video, :channel)) in videos.values.indexed)
        (
          videoId: video['id'] as String,
          caption: video['thumbnailCaption'] as String?,
          emoji: (channel['picture'] as _Json)['emoji'] as String,
          colors: _colors(channel['picture'] as _Json),
          live: channel['live'] == true,
          layout: i % 4,
        ),
    ],
  );
}
