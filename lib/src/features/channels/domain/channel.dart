import 'package:dart_mappable/dart_mappable.dart';

part 'channel.mapper.dart';

/// Stands in for the channel of comments and live chats whose video's
/// channel isn't known: its details aren't loaded (e.g. signed out), the
/// video is gone, or the item is on a post. Never a real channel ID, which
/// always starts with "UC".
const unknownChannelId = '_unknown';

@MappableClass()
class Channel with ChannelMappable {
  final String channelId;
  final String? channelTitle;
  final String? channelUrl;
  final String? thumbnailUrl;
  final int commentCount;
  final int liveChatCount;

  const Channel({
    required this.channelId,
    this.channelTitle,
    this.channelUrl,
    this.thumbnailUrl,
    required this.commentCount,
    required this.liveChatCount,
  });

  int get totalInteractions => commentCount + liveChatCount;

  /// Whether this groups items whose channel isn't known, rather than being
  /// a real channel.
  bool get isUnknown => channelId == unknownChannelId;
}
