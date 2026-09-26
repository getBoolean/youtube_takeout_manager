import 'package:dart_mappable/dart_mappable.dart';

import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'deletion_item_status.dart';

part 'deletion_queue_item.mapper.dart';

@MappableClass()
class DeletionQueueItem with DeletionQueueItemMappable {
  final String id;
  final String itemId;
  final QueueItemKind itemType;
  final DeletionItemStatus status;
  final String? displayTextSnippet;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? processedAt;

  /// The channel that wrote the comment or live chat, whose sign-in deletes
  /// it. Null for items queued before this was saved, until the takeout they
  /// came from is loaded.
  final String? authorChannelId;

  const DeletionQueueItem({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.status,
    this.displayTextSnippet,
    this.errorMessage,
    required this.createdAt,
    this.processedAt,
    this.authorChannelId,
  });
}
