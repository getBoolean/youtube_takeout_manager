// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'takeout_data.dart';

class TakeoutDataMapper extends ClassMapperBase<TakeoutData> {
  TakeoutDataMapper._();

  static TakeoutDataMapper? _instance;
  static TakeoutDataMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TakeoutDataMapper._());
      CommentMapper.ensureInitialized();
      LiveChatMapper.ensureInitialized();
      SubscriptionMapper.ensureInitialized();
      KindSnapshotMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'TakeoutData';

  static List<Comment> _$comments(TakeoutData v) => v.comments;
  static const Field<TakeoutData, List<Comment>> _f$comments = Field(
    'comments',
    _$comments,
  );
  static List<LiveChat> _$liveChats(TakeoutData v) => v.liveChats;
  static const Field<TakeoutData, List<LiveChat>> _f$liveChats = Field(
    'liveChats',
    _$liveChats,
  );
  static Map<String, Subscription> _$subscriptionsByChannelId(TakeoutData v) =>
      v.subscriptionsByChannelId;
  static const Field<TakeoutData, Map<String, Subscription>>
  _f$subscriptionsByChannelId = Field(
    'subscriptionsByChannelId',
    _$subscriptionsByChannelId,
  );
  static int _$rawCommentLines(TakeoutData v) => v.rawCommentLines;
  static const Field<TakeoutData, int> _f$rawCommentLines = Field(
    'rawCommentLines',
    _$rawCommentLines,
    opt: true,
    def: 0,
  );
  static int _$rawLiveChatLines(TakeoutData v) => v.rawLiveChatLines;
  static const Field<TakeoutData, int> _f$rawLiveChatLines = Field(
    'rawLiveChatLines',
    _$rawLiveChatLines,
    opt: true,
    def: 0,
  );
  static int _$parsedCommentRows(TakeoutData v) => v.parsedCommentRows;
  static const Field<TakeoutData, int> _f$parsedCommentRows = Field(
    'parsedCommentRows',
    _$parsedCommentRows,
    opt: true,
    def: 0,
  );
  static int _$parsedLiveChatRows(TakeoutData v) => v.parsedLiveChatRows;
  static const Field<TakeoutData, int> _f$parsedLiveChatRows = Field(
    'parsedLiveChatRows',
    _$parsedLiveChatRows,
    opt: true,
    def: 0,
  );
  static int _$skippedCommentRows(TakeoutData v) => v.skippedCommentRows;
  static const Field<TakeoutData, int> _f$skippedCommentRows = Field(
    'skippedCommentRows',
    _$skippedCommentRows,
    opt: true,
    def: 0,
  );
  static int _$skippedLiveChatRows(TakeoutData v) => v.skippedLiveChatRows;
  static const Field<TakeoutData, int> _f$skippedLiveChatRows = Field(
    'skippedLiveChatRows',
    _$skippedLiveChatRows,
    opt: true,
    def: 0,
  );
  static DateTime? _$latestExportAt(TakeoutData v) => v.latestExportAt;
  static const Field<TakeoutData, DateTime> _f$latestExportAt = Field(
    'latestExportAt',
    _$latestExportAt,
    opt: true,
  );
  static KindSnapshot? _$commentsSnapshot(TakeoutData v) => v.commentsSnapshot;
  static const Field<TakeoutData, KindSnapshot> _f$commentsSnapshot = Field(
    'commentsSnapshot',
    _$commentsSnapshot,
    opt: true,
  );
  static KindSnapshot? _$liveChatsSnapshot(TakeoutData v) =>
      v.liveChatsSnapshot;
  static const Field<TakeoutData, KindSnapshot> _f$liveChatsSnapshot = Field(
    'liveChatsSnapshot',
    _$liveChatsSnapshot,
    opt: true,
  );

  @override
  final MappableFields<TakeoutData> fields = const {
    #comments: _f$comments,
    #liveChats: _f$liveChats,
    #subscriptionsByChannelId: _f$subscriptionsByChannelId,
    #rawCommentLines: _f$rawCommentLines,
    #rawLiveChatLines: _f$rawLiveChatLines,
    #parsedCommentRows: _f$parsedCommentRows,
    #parsedLiveChatRows: _f$parsedLiveChatRows,
    #skippedCommentRows: _f$skippedCommentRows,
    #skippedLiveChatRows: _f$skippedLiveChatRows,
    #latestExportAt: _f$latestExportAt,
    #commentsSnapshot: _f$commentsSnapshot,
    #liveChatsSnapshot: _f$liveChatsSnapshot,
  };

  static TakeoutData _instantiate(DecodingData data) {
    return TakeoutData(
      comments: data.dec(_f$comments),
      liveChats: data.dec(_f$liveChats),
      subscriptionsByChannelId: data.dec(_f$subscriptionsByChannelId),
      rawCommentLines: data.dec(_f$rawCommentLines),
      rawLiveChatLines: data.dec(_f$rawLiveChatLines),
      parsedCommentRows: data.dec(_f$parsedCommentRows),
      parsedLiveChatRows: data.dec(_f$parsedLiveChatRows),
      skippedCommentRows: data.dec(_f$skippedCommentRows),
      skippedLiveChatRows: data.dec(_f$skippedLiveChatRows),
      latestExportAt: data.dec(_f$latestExportAt),
      commentsSnapshot: data.dec(_f$commentsSnapshot),
      liveChatsSnapshot: data.dec(_f$liveChatsSnapshot),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static TakeoutData fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<TakeoutData>(map);
  }

  static TakeoutData fromJson(String json) {
    return ensureInitialized().decodeJson<TakeoutData>(json);
  }
}

mixin TakeoutDataMappable {
  String toJson() {
    return TakeoutDataMapper.ensureInitialized().encodeJson<TakeoutData>(
      this as TakeoutData,
    );
  }

  Map<String, dynamic> toMap() {
    return TakeoutDataMapper.ensureInitialized().encodeMap<TakeoutData>(
      this as TakeoutData,
    );
  }

  TakeoutDataCopyWith<TakeoutData, TakeoutData, TakeoutData> get copyWith =>
      _TakeoutDataCopyWithImpl<TakeoutData, TakeoutData>(
        this as TakeoutData,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return TakeoutDataMapper.ensureInitialized().stringifyValue(
      this as TakeoutData,
    );
  }

  @override
  bool operator ==(Object other) {
    return TakeoutDataMapper.ensureInitialized().equalsValue(
      this as TakeoutData,
      other,
    );
  }

  @override
  int get hashCode {
    return TakeoutDataMapper.ensureInitialized().hashValue(this as TakeoutData);
  }
}

extension TakeoutDataValueCopy<$R, $Out>
    on ObjectCopyWith<$R, TakeoutData, $Out> {
  TakeoutDataCopyWith<$R, TakeoutData, $Out> get $asTakeoutData =>
      $base.as((v, t, t2) => _TakeoutDataCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class TakeoutDataCopyWith<$R, $In extends TakeoutData, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, Comment, CommentCopyWith<$R, Comment, Comment>> get comments;
  ListCopyWith<$R, LiveChat, LiveChatCopyWith<$R, LiveChat, LiveChat>>
  get liveChats;
  MapCopyWith<
    $R,
    String,
    Subscription,
    SubscriptionCopyWith<$R, Subscription, Subscription>
  >
  get subscriptionsByChannelId;
  KindSnapshotCopyWith<$R, KindSnapshot, KindSnapshot>? get commentsSnapshot;
  KindSnapshotCopyWith<$R, KindSnapshot, KindSnapshot>? get liveChatsSnapshot;
  $R call({
    List<Comment>? comments,
    List<LiveChat>? liveChats,
    Map<String, Subscription>? subscriptionsByChannelId,
    int? rawCommentLines,
    int? rawLiveChatLines,
    int? parsedCommentRows,
    int? parsedLiveChatRows,
    int? skippedCommentRows,
    int? skippedLiveChatRows,
    DateTime? latestExportAt,
    KindSnapshot? commentsSnapshot,
    KindSnapshot? liveChatsSnapshot,
  });
  TakeoutDataCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _TakeoutDataCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, TakeoutData, $Out>
    implements TakeoutDataCopyWith<$R, TakeoutData, $Out> {
  _TakeoutDataCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<TakeoutData> $mapper =
      TakeoutDataMapper.ensureInitialized();
  @override
  ListCopyWith<$R, Comment, CommentCopyWith<$R, Comment, Comment>>
  get comments => ListCopyWith(
    $value.comments,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(comments: v),
  );
  @override
  ListCopyWith<$R, LiveChat, LiveChatCopyWith<$R, LiveChat, LiveChat>>
  get liveChats => ListCopyWith(
    $value.liveChats,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(liveChats: v),
  );
  @override
  MapCopyWith<
    $R,
    String,
    Subscription,
    SubscriptionCopyWith<$R, Subscription, Subscription>
  >
  get subscriptionsByChannelId => MapCopyWith(
    $value.subscriptionsByChannelId,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(subscriptionsByChannelId: v),
  );
  @override
  KindSnapshotCopyWith<$R, KindSnapshot, KindSnapshot>? get commentsSnapshot =>
      $value.commentsSnapshot?.copyWith.$chain(
        (v) => call(commentsSnapshot: v),
      );
  @override
  KindSnapshotCopyWith<$R, KindSnapshot, KindSnapshot>? get liveChatsSnapshot =>
      $value.liveChatsSnapshot?.copyWith.$chain(
        (v) => call(liveChatsSnapshot: v),
      );
  @override
  $R call({
    List<Comment>? comments,
    List<LiveChat>? liveChats,
    Map<String, Subscription>? subscriptionsByChannelId,
    int? rawCommentLines,
    int? rawLiveChatLines,
    int? parsedCommentRows,
    int? parsedLiveChatRows,
    int? skippedCommentRows,
    int? skippedLiveChatRows,
    Object? latestExportAt = $none,
    Object? commentsSnapshot = $none,
    Object? liveChatsSnapshot = $none,
  }) => $apply(
    FieldCopyWithData({
      if (comments != null) #comments: comments,
      if (liveChats != null) #liveChats: liveChats,
      if (subscriptionsByChannelId != null)
        #subscriptionsByChannelId: subscriptionsByChannelId,
      if (rawCommentLines != null) #rawCommentLines: rawCommentLines,
      if (rawLiveChatLines != null) #rawLiveChatLines: rawLiveChatLines,
      if (parsedCommentRows != null) #parsedCommentRows: parsedCommentRows,
      if (parsedLiveChatRows != null) #parsedLiveChatRows: parsedLiveChatRows,
      if (skippedCommentRows != null) #skippedCommentRows: skippedCommentRows,
      if (skippedLiveChatRows != null)
        #skippedLiveChatRows: skippedLiveChatRows,
      if (latestExportAt != $none) #latestExportAt: latestExportAt,
      if (commentsSnapshot != $none) #commentsSnapshot: commentsSnapshot,
      if (liveChatsSnapshot != $none) #liveChatsSnapshot: liveChatsSnapshot,
    }),
  );
  @override
  TakeoutData $make(CopyWithData data) => TakeoutData(
    comments: data.get(#comments, or: $value.comments),
    liveChats: data.get(#liveChats, or: $value.liveChats),
    subscriptionsByChannelId: data.get(
      #subscriptionsByChannelId,
      or: $value.subscriptionsByChannelId,
    ),
    rawCommentLines: data.get(#rawCommentLines, or: $value.rawCommentLines),
    rawLiveChatLines: data.get(#rawLiveChatLines, or: $value.rawLiveChatLines),
    parsedCommentRows: data.get(
      #parsedCommentRows,
      or: $value.parsedCommentRows,
    ),
    parsedLiveChatRows: data.get(
      #parsedLiveChatRows,
      or: $value.parsedLiveChatRows,
    ),
    skippedCommentRows: data.get(
      #skippedCommentRows,
      or: $value.skippedCommentRows,
    ),
    skippedLiveChatRows: data.get(
      #skippedLiveChatRows,
      or: $value.skippedLiveChatRows,
    ),
    latestExportAt: data.get(#latestExportAt, or: $value.latestExportAt),
    commentsSnapshot: data.get(#commentsSnapshot, or: $value.commentsSnapshot),
    liveChatsSnapshot: data.get(
      #liveChatsSnapshot,
      or: $value.liveChatsSnapshot,
    ),
  );

  @override
  TakeoutDataCopyWith<$R2, TakeoutData, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _TakeoutDataCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class KindSnapshotMapper extends ClassMapperBase<KindSnapshot> {
  KindSnapshotMapper._();

  static KindSnapshotMapper? _instance;
  static KindSnapshotMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = KindSnapshotMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'KindSnapshot';

  static DateTime _$exportedAt(KindSnapshot v) => v.exportedAt;
  static const Field<KindSnapshot, DateTime> _f$exportedAt = Field(
    'exportedAt',
    _$exportedAt,
  );
  static bool _$complete(KindSnapshot v) => v.complete;
  static const Field<KindSnapshot, bool> _f$complete = Field(
    'complete',
    _$complete,
  );

  @override
  final MappableFields<KindSnapshot> fields = const {
    #exportedAt: _f$exportedAt,
    #complete: _f$complete,
  };

  static KindSnapshot _instantiate(DecodingData data) {
    return KindSnapshot(
      exportedAt: data.dec(_f$exportedAt),
      complete: data.dec(_f$complete),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static KindSnapshot fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<KindSnapshot>(map);
  }

  static KindSnapshot fromJson(String json) {
    return ensureInitialized().decodeJson<KindSnapshot>(json);
  }
}

mixin KindSnapshotMappable {
  String toJson() {
    return KindSnapshotMapper.ensureInitialized().encodeJson<KindSnapshot>(
      this as KindSnapshot,
    );
  }

  Map<String, dynamic> toMap() {
    return KindSnapshotMapper.ensureInitialized().encodeMap<KindSnapshot>(
      this as KindSnapshot,
    );
  }

  KindSnapshotCopyWith<KindSnapshot, KindSnapshot, KindSnapshot> get copyWith =>
      _KindSnapshotCopyWithImpl<KindSnapshot, KindSnapshot>(
        this as KindSnapshot,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return KindSnapshotMapper.ensureInitialized().stringifyValue(
      this as KindSnapshot,
    );
  }

  @override
  bool operator ==(Object other) {
    return KindSnapshotMapper.ensureInitialized().equalsValue(
      this as KindSnapshot,
      other,
    );
  }

  @override
  int get hashCode {
    return KindSnapshotMapper.ensureInitialized().hashValue(
      this as KindSnapshot,
    );
  }
}

extension KindSnapshotValueCopy<$R, $Out>
    on ObjectCopyWith<$R, KindSnapshot, $Out> {
  KindSnapshotCopyWith<$R, KindSnapshot, $Out> get $asKindSnapshot =>
      $base.as((v, t, t2) => _KindSnapshotCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class KindSnapshotCopyWith<$R, $In extends KindSnapshot, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({DateTime? exportedAt, bool? complete});
  KindSnapshotCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _KindSnapshotCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, KindSnapshot, $Out>
    implements KindSnapshotCopyWith<$R, KindSnapshot, $Out> {
  _KindSnapshotCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<KindSnapshot> $mapper =
      KindSnapshotMapper.ensureInitialized();
  @override
  $R call({DateTime? exportedAt, bool? complete}) => $apply(
    FieldCopyWithData({
      if (exportedAt != null) #exportedAt: exportedAt,
      if (complete != null) #complete: complete,
    }),
  );
  @override
  KindSnapshot $make(CopyWithData data) => KindSnapshot(
    exportedAt: data.get(#exportedAt, or: $value.exportedAt),
    complete: data.get(#complete, or: $value.complete),
  );

  @override
  KindSnapshotCopyWith<$R2, KindSnapshot, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _KindSnapshotCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

