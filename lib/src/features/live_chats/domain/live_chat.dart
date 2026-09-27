import 'package:dart_mappable/dart_mappable.dart';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';

part 'live_chat.mapper.dart';

@MappableClass()
class LiveChat with LiveChatMappable implements Interaction {
  final String liveChatId;
  final String channelId;
  @override
  final DateTime createdAt;
  final double price;
  final String? currencyCode;
  @override
  final String? videoId;
  @override
  final String rawText;
  @override
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

  @override
  String get id => liveChatId;
  @override
  QueueItemKind get kind => QueueItemKind.liveChat;
  @override
  String? get postId => null;
  @override
  T when<T>({
    required T Function(Comment) comment,
    required T Function(LiveChat) liveChat,
  }) => liveChat(this);
}
