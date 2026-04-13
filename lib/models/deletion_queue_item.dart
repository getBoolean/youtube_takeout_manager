import 'package:dart_mappable/dart_mappable.dart';

import 'deletion_item_status.dart';
import 'deletion_item_type.dart';

part 'deletion_queue_item.mapper.dart';

@MappableClass()
class DeletionQueueItem with DeletionQueueItemMappable {
  final String id;
  final String itemId;
  final DeletionItemType itemType;
  final DeletionItemStatus status;
  final String? displayTextSnippet;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? processedAt;

  const DeletionQueueItem({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.status,
    this.displayTextSnippet,
    this.errorMessage,
    required this.createdAt,
    this.processedAt,
  });
}
