import 'package:dart_mappable/dart_mappable.dart';

part 'queue_item_kind.mapper.dart';

/// Classifies a deletion queue entry by its source in the Takeout export.
///
/// Does NOT drive the deletion API — both kinds are deleted via
/// `comments.delete`. Used for UI labeling, persistence bucketing, and
/// enqueue deduplication.
@MappableEnum()
enum QueueItemKind { comment, liveChat }
