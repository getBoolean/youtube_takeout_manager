import 'package:dart_mappable/dart_mappable.dart';

part 'channel.mapper.dart';

@MappableClass()
class Channel with ChannelMappable {
  final String channelId;
  final String? channelTitle;
  final String? channelUrl;
  final int commentCount;
  final int liveChatCount;

  const Channel({
    required this.channelId,
    this.channelTitle,
    this.channelUrl,
    required this.commentCount,
    required this.liveChatCount,
  });

  int get totalInteractions => commentCount + liveChatCount;
}
