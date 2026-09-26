import 'package:dart_mappable/dart_mappable.dart';

import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';

part 'channel.mapper.dart';

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
