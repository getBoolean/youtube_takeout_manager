// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'deletion_queue_item.dart';

class DeletionQueueItemMapper extends ClassMapperBase<DeletionQueueItem> {
  DeletionQueueItemMapper._();

  static DeletionQueueItemMapper? _instance;
  static DeletionQueueItemMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DeletionQueueItemMapper._());
      QueueItemKindMapper.ensureInitialized();
      DeletionItemStatusMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'DeletionQueueItem';

  static String _$id(DeletionQueueItem v) => v.id;
  static const Field<DeletionQueueItem, String> _f$id = Field('id', _$id);
  static String _$itemId(DeletionQueueItem v) => v.itemId;
  static const Field<DeletionQueueItem, String> _f$itemId = Field(
    'itemId',
    _$itemId,
  );
  static QueueItemKind _$itemType(DeletionQueueItem v) => v.itemType;
  static const Field<DeletionQueueItem, QueueItemKind> _f$itemType = Field(
    'itemType',
    _$itemType,
  );
  static DeletionItemStatus _$status(DeletionQueueItem v) => v.status;
  static const Field<DeletionQueueItem, DeletionItemStatus> _f$status = Field(
    'status',
    _$status,
  );
  static String? _$displayTextSnippet(DeletionQueueItem v) =>
      v.displayTextSnippet;
  static const Field<DeletionQueueItem, String> _f$displayTextSnippet = Field(
    'displayTextSnippet',
    _$displayTextSnippet,
    opt: true,
  );
  static String? _$errorMessage(DeletionQueueItem v) => v.errorMessage;
  static const Field<DeletionQueueItem, String> _f$errorMessage = Field(
    'errorMessage',
    _$errorMessage,
    opt: true,
  );
  static DateTime _$createdAt(DeletionQueueItem v) => v.createdAt;
  static const Field<DeletionQueueItem, DateTime> _f$createdAt = Field(
    'createdAt',
    _$createdAt,
  );
  static DateTime? _$processedAt(DeletionQueueItem v) => v.processedAt;
  static const Field<DeletionQueueItem, DateTime> _f$processedAt = Field(
    'processedAt',
    _$processedAt,
    opt: true,
  );
  static String? _$authorChannelId(DeletionQueueItem v) => v.authorChannelId;
  static const Field<DeletionQueueItem, String> _f$authorChannelId = Field(
    'authorChannelId',
    _$authorChannelId,
    opt: true,
  );

  @override
  final MappableFields<DeletionQueueItem> fields = const {
    #id: _f$id,
    #itemId: _f$itemId,
    #itemType: _f$itemType,
    #status: _f$status,
    #displayTextSnippet: _f$displayTextSnippet,
    #errorMessage: _f$errorMessage,
    #createdAt: _f$createdAt,
    #processedAt: _f$processedAt,
    #authorChannelId: _f$authorChannelId,
  };

  static DeletionQueueItem _instantiate(DecodingData data) {
    return DeletionQueueItem(
      id: data.dec(_f$id),
      itemId: data.dec(_f$itemId),
      itemType: data.dec(_f$itemType),
      status: data.dec(_f$status),
      displayTextSnippet: data.dec(_f$displayTextSnippet),
      errorMessage: data.dec(_f$errorMessage),
      createdAt: data.dec(_f$createdAt),
      processedAt: data.dec(_f$processedAt),
      authorChannelId: data.dec(_f$authorChannelId),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static DeletionQueueItem fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DeletionQueueItem>(map);
  }

  static DeletionQueueItem fromJson(String json) {
    return ensureInitialized().decodeJson<DeletionQueueItem>(json);
  }
}

mixin DeletionQueueItemMappable {
  String toJson() {
    return DeletionQueueItemMapper.ensureInitialized()
        .encodeJson<DeletionQueueItem>(this as DeletionQueueItem);
  }

  Map<String, dynamic> toMap() {
    return DeletionQueueItemMapper.ensureInitialized()
        .encodeMap<DeletionQueueItem>(this as DeletionQueueItem);
  }

  DeletionQueueItemCopyWith<
    DeletionQueueItem,
    DeletionQueueItem,
    DeletionQueueItem
  >
  get copyWith =>
      _DeletionQueueItemCopyWithImpl<DeletionQueueItem, DeletionQueueItem>(
        this as DeletionQueueItem,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return DeletionQueueItemMapper.ensureInitialized().stringifyValue(
      this as DeletionQueueItem,
    );
  }

  @override
  bool operator ==(Object other) {
    return DeletionQueueItemMapper.ensureInitialized().equalsValue(
      this as DeletionQueueItem,
      other,
    );
  }

  @override
  int get hashCode {
    return DeletionQueueItemMapper.ensureInitialized().hashValue(
      this as DeletionQueueItem,
    );
  }
}

extension DeletionQueueItemValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DeletionQueueItem, $Out> {
  DeletionQueueItemCopyWith<$R, DeletionQueueItem, $Out>
  get $asDeletionQueueItem => $base.as(
    (v, t, t2) => _DeletionQueueItemCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class DeletionQueueItemCopyWith<
  $R,
  $In extends DeletionQueueItem,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? itemId,
    QueueItemKind? itemType,
    DeletionItemStatus? status,
    String? displayTextSnippet,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? processedAt,
    String? authorChannelId,
  });
  DeletionQueueItemCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _DeletionQueueItemCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DeletionQueueItem, $Out>
    implements DeletionQueueItemCopyWith<$R, DeletionQueueItem, $Out> {
  _DeletionQueueItemCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DeletionQueueItem> $mapper =
      DeletionQueueItemMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    String? itemId,
    QueueItemKind? itemType,
    DeletionItemStatus? status,
    Object? displayTextSnippet = $none,
    Object? errorMessage = $none,
    DateTime? createdAt,
    Object? processedAt = $none,
    Object? authorChannelId = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (itemId != null) #itemId: itemId,
      if (itemType != null) #itemType: itemType,
      if (status != null) #status: status,
      if (displayTextSnippet != $none) #displayTextSnippet: displayTextSnippet,
      if (errorMessage != $none) #errorMessage: errorMessage,
      if (createdAt != null) #createdAt: createdAt,
      if (processedAt != $none) #processedAt: processedAt,
      if (authorChannelId != $none) #authorChannelId: authorChannelId,
    }),
  );
  @override
  DeletionQueueItem $make(CopyWithData data) => DeletionQueueItem(
    id: data.get(#id, or: $value.id),
    itemId: data.get(#itemId, or: $value.itemId),
    itemType: data.get(#itemType, or: $value.itemType),
    status: data.get(#status, or: $value.status),
    displayTextSnippet: data.get(
      #displayTextSnippet,
      or: $value.displayTextSnippet,
    ),
    errorMessage: data.get(#errorMessage, or: $value.errorMessage),
    createdAt: data.get(#createdAt, or: $value.createdAt),
    processedAt: data.get(#processedAt, or: $value.processedAt),
    authorChannelId: data.get(#authorChannelId, or: $value.authorChannelId),
  );

  @override
  DeletionQueueItemCopyWith<$R2, DeletionQueueItem, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _DeletionQueueItemCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

