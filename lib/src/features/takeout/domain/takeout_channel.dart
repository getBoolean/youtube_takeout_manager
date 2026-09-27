import 'package:dart_mappable/dart_mappable.dart';

import 'own_channel.dart';
import 'takeout_data.dart';

part 'takeout_channel.mapper.dart';

/// One YouTube channel in a saved takeout: listed in its channel.csv, or the
/// author of some of its comments or live chats.
@MappableClass()
class TakeoutChannel with TakeoutChannelMappable {
  final String channelId;
  final String? title;

  /// See [OwnChannel.vanityName].
  final String? vanityName;

  /// Whether this is the takeout's main channel: the only one its
  /// channel.csv lists, otherwise the one the takeout is saved under.
  final bool isMain;

  /// Whether the takeout's channel.csv lists it.
  final bool listed;

  final int commentCount;
  final int liveChatCount;

  /// The channel's picture, when known. Takeouts don't have it; it comes
  /// from a saved sign-in or pictures already loaded.
  final String? thumbnailUrl;

  const TakeoutChannel({
    required this.channelId,
    this.title,
    this.vanityName,
    required this.isMain,
    required this.listed,
    this.commentCount = 0,
    this.liveChatCount = 0,
    this.thumbnailUrl,
  });

  /// Its title, or its ID when the takeout doesn't give one.
  String get displayName => title ?? channelId;
}

/// What the takeout switcher shows about a saved takeout, read without
/// loading all of its data.
@MappableClass()
class TakeoutSummary with TakeoutSummaryMappable {
  /// The ID the takeout is saved under.
  final String id;

  /// Main channel first, like [takeoutChannelsOf].
  final List<TakeoutChannel> channels;
  final DateTime? latestExportAt;

  /// Whether the channels' item counts are known. Data saved before
  /// summaries were written only knows its ID.
  final bool countsKnown;

  const TakeoutSummary({
    required this.id,
    required this.channels,
    this.latestExportAt,
    required this.countsKnown,
  });

  TakeoutChannel get main => channels.first;

  Set<String> get channelIds => {for (final c in channels) c.channelId};
}

/// Every channel in [data], main channel first, then by how many items they
/// wrote. Rows without a Channel ID count as the main channel's.
List<TakeoutChannel> takeoutChannelsOf(
  TakeoutData data, {
  required String takeoutId,
}) => takeoutChannelsFrom(takeoutId, data.ownChannels, data.countsByAuthor);

/// The channel to show from [channels]: [remembered] while it's still there,
/// otherwise the main channel. Null when there are none.
String? resolveViewedChannelId(
  List<TakeoutChannel> channels, {
  String? remembered,
}) {
  if (channels.any((c) => c.channelId == remembered)) return remembered;
  for (final c in channels) {
    if (c.isMain) return c.channelId;
  }
  return channels.firstOrNull?.channelId;
}

/// Only [channelId]'s comments and live chats from [data]. Rows without a
/// Channel ID count as [mainChannelId]'s. Returns [data] itself when nothing
/// is left out.
TakeoutData onlyChannel(
  TakeoutData data,
  String channelId, {
  required String mainChannelId,
}) {
  bool keeps(String author) =>
      authorChannelId(author, mainChannelId: mainChannelId) == channelId;
  final comments = [
    for (final c in data.comments)
      if (keeps(c.channelId)) c,
  ];
  final liveChats = [
    for (final l in data.liveChats)
      if (keeps(l.channelId)) l,
  ];
  if (comments.length == data.comments.length &&
      liveChats.length == data.liveChats.length) {
    return data;
  }
  return data.copyWith(comments: comments, liveChats: liveChats);
}

const _none = (comments: 0, liveChats: 0);

/// The channels of a takeout saved under [takeoutId] that lists [own] in its
/// channel.csv, whose authors wrote [counts] ('' for rows without a Channel
/// ID).
List<TakeoutChannel> takeoutChannelsFrom(
  String takeoutId,
  Map<String, OwnChannel> own,
  Map<String, ItemCounts> counts,
) {
  final mainId = listedMainChannelIdOf(own) ?? takeoutId;
  final byChannel = <String, ItemCounts>{};
  counts.forEach((author, n) {
    final id = authorChannelId(author, mainChannelId: mainId);
    final sum = byChannel[id] ?? _none;
    byChannel[id] = (
      comments: sum.comments + n.comments,
      liveChats: sum.liveChats + n.liveChats,
    );
  });

  final channels = [
    for (final id in {mainId, ...own.keys, ...byChannel.keys})
      TakeoutChannel(
        channelId: id,
        title: own[id]?.title,
        vanityName: own[id]?.vanityName,
        isMain: id == mainId,
        listed: own.containsKey(id),
        commentCount: byChannel[id]?.comments ?? 0,
        liveChatCount: byChannel[id]?.liveChats ?? 0,
      ),
  ];
  int total(TakeoutChannel c) => c.commentCount + c.liveChatCount;
  return channels..sort((a, b) {
    if (a.isMain != b.isMain) return a.isMain ? -1 : 1;
    final byCount = total(b).compareTo(total(a));
    return byCount != 0 ? byCount : a.channelId.compareTo(b.channelId);
  });
}

/// [channels], each without a title taking one from [titles] by channel ID.
List<TakeoutChannel> withTitles(
  List<TakeoutChannel> channels,
  Map<String, String> titles,
) => [
  for (final c in channels)
    if (c.title == null && titles[c.channelId] != null)
      c.copyWith(title: titles[c.channelId])
    else
      c,
];

/// [channels], each without a picture taking one from [thumbnails] by
/// channel ID.
List<TakeoutChannel> withThumbnails(
  List<TakeoutChannel> channels,
  Map<String, String> thumbnails,
) => [
  for (final c in channels)
    if (c.thumbnailUrl == null && thumbnails[c.channelId] != null)
      c.copyWith(thumbnailUrl: thumbnails[c.channelId])
    else
      c,
];
