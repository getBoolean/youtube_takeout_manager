import 'package:dart_mappable/dart_mappable.dart';

part 'live_chat.mapper.dart';

@MappableClass()
class LiveChat with LiveChatMappable {
  final String liveChatId;
  final String channelId;
  final DateTime createdAt;
  final double price;
  final String? currencyCode;
  final String? videoId;
  final String rawText;
  final String displayText;

  const LiveChat({
    required this.liveChatId,
    required this.channelId,
    required this.createdAt,
    required this.price,
    this.currencyCode,
    this.videoId,
    required this.rawText,
    required this.displayText,
  });
}
