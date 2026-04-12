import 'package:dart_mappable/dart_mappable.dart';

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
}
