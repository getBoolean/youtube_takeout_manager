import 'package:dart_mappable/dart_mappable.dart';

part 'deletion_item_status.mapper.dart';

@MappableEnum()
enum DeletionItemStatus {
  pending,
  inProgress,
  succeeded,
  failed,
  quotaExceeded,
}
