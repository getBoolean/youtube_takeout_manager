// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'takeout_channel.dart';

class TakeoutChannelMapper extends ClassMapperBase<TakeoutChannel> {
  TakeoutChannelMapper._();

  static TakeoutChannelMapper? _instance;
  static TakeoutChannelMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TakeoutChannelMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'TakeoutChannel';

  static String _$channelId(TakeoutChannel v) => v.channelId;
  static const Field<TakeoutChannel, String> _f$channelId = Field(
    'channelId',
    _$channelId,
  );
  static String? _$title(TakeoutChannel v) => v.title;
  static const Field<TakeoutChannel, String> _f$title = Field(
    'title',
    _$title,
    opt: true,
  );
  static String? _$vanityName(TakeoutChannel v) => v.vanityName;
  static const Field<TakeoutChannel, String> _f$vanityName = Field(
    'vanityName',
    _$vanityName,
    opt: true,
  );
  static bool _$isMain(TakeoutChannel v) => v.isMain;
  static const Field<TakeoutChannel, bool> _f$isMain = Field(
    'isMain',
    _$isMain,
  );
  static bool _$listed(TakeoutChannel v) => v.listed;
  static const Field<TakeoutChannel, bool> _f$listed = Field(
    'listed',
    _$listed,
  );
  static int _$commentCount(TakeoutChannel v) => v.commentCount;
  static const Field<TakeoutChannel, int> _f$commentCount = Field(
    'commentCount',
    _$commentCount,
    opt: true,
    def: 0,
  );
  static int _$liveChatCount(TakeoutChannel v) => v.liveChatCount;
  static const Field<TakeoutChannel, int> _f$liveChatCount = Field(
    'liveChatCount',
    _$liveChatCount,
    opt: true,
    def: 0,
  );

  @override
  final MappableFields<TakeoutChannel> fields = const {
    #channelId: _f$channelId,
    #title: _f$title,
    #vanityName: _f$vanityName,
    #isMain: _f$isMain,
    #listed: _f$listed,
    #commentCount: _f$commentCount,
    #liveChatCount: _f$liveChatCount,
  };

  static TakeoutChannel _instantiate(DecodingData data) {
    return TakeoutChannel(
      channelId: data.dec(_f$channelId),
      title: data.dec(_f$title),
      vanityName: data.dec(_f$vanityName),
      isMain: data.dec(_f$isMain),
      listed: data.dec(_f$listed),
      commentCount: data.dec(_f$commentCount),
      liveChatCount: data.dec(_f$liveChatCount),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static TakeoutChannel fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<TakeoutChannel>(map);
  }

  static TakeoutChannel fromJson(String json) {
    return ensureInitialized().decodeJson<TakeoutChannel>(json);
  }
}

mixin TakeoutChannelMappable {
  String toJson() {
    return TakeoutChannelMapper.ensureInitialized().encodeJson<TakeoutChannel>(
      this as TakeoutChannel,
    );
  }

  Map<String, dynamic> toMap() {
    return TakeoutChannelMapper.ensureInitialized().encodeMap<TakeoutChannel>(
      this as TakeoutChannel,
    );
  }

  TakeoutChannelCopyWith<TakeoutChannel, TakeoutChannel, TakeoutChannel>
  get copyWith => _TakeoutChannelCopyWithImpl<TakeoutChannel, TakeoutChannel>(
    this as TakeoutChannel,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return TakeoutChannelMapper.ensureInitialized().stringifyValue(
      this as TakeoutChannel,
    );
  }

  @override
  bool operator ==(Object other) {
    return TakeoutChannelMapper.ensureInitialized().equalsValue(
      this as TakeoutChannel,
      other,
    );
  }

  @override
  int get hashCode {
    return TakeoutChannelMapper.ensureInitialized().hashValue(
      this as TakeoutChannel,
    );
  }
}

extension TakeoutChannelValueCopy<$R, $Out>
    on ObjectCopyWith<$R, TakeoutChannel, $Out> {
  TakeoutChannelCopyWith<$R, TakeoutChannel, $Out> get $asTakeoutChannel =>
      $base.as((v, t, t2) => _TakeoutChannelCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class TakeoutChannelCopyWith<$R, $In extends TakeoutChannel, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? channelId,
    String? title,
    String? vanityName,
    bool? isMain,
    bool? listed,
    int? commentCount,
    int? liveChatCount,
  });
  TakeoutChannelCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _TakeoutChannelCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, TakeoutChannel, $Out>
    implements TakeoutChannelCopyWith<$R, TakeoutChannel, $Out> {
  _TakeoutChannelCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<TakeoutChannel> $mapper =
      TakeoutChannelMapper.ensureInitialized();
  @override
  $R call({
    String? channelId,
    Object? title = $none,
    Object? vanityName = $none,
    bool? isMain,
    bool? listed,
    int? commentCount,
    int? liveChatCount,
  }) => $apply(
    FieldCopyWithData({
      if (channelId != null) #channelId: channelId,
      if (title != $none) #title: title,
      if (vanityName != $none) #vanityName: vanityName,
      if (isMain != null) #isMain: isMain,
      if (listed != null) #listed: listed,
      if (commentCount != null) #commentCount: commentCount,
      if (liveChatCount != null) #liveChatCount: liveChatCount,
    }),
  );
  @override
  TakeoutChannel $make(CopyWithData data) => TakeoutChannel(
    channelId: data.get(#channelId, or: $value.channelId),
    title: data.get(#title, or: $value.title),
    vanityName: data.get(#vanityName, or: $value.vanityName),
    isMain: data.get(#isMain, or: $value.isMain),
    listed: data.get(#listed, or: $value.listed),
    commentCount: data.get(#commentCount, or: $value.commentCount),
    liveChatCount: data.get(#liveChatCount, or: $value.liveChatCount),
  );

  @override
  TakeoutChannelCopyWith<$R2, TakeoutChannel, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _TakeoutChannelCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class TakeoutSummaryMapper extends ClassMapperBase<TakeoutSummary> {
  TakeoutSummaryMapper._();

  static TakeoutSummaryMapper? _instance;
  static TakeoutSummaryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TakeoutSummaryMapper._());
      TakeoutChannelMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'TakeoutSummary';

  static String _$id(TakeoutSummary v) => v.id;
  static const Field<TakeoutSummary, String> _f$id = Field('id', _$id);
  static List<TakeoutChannel> _$channels(TakeoutSummary v) => v.channels;
  static const Field<TakeoutSummary, List<TakeoutChannel>> _f$channels = Field(
    'channels',
    _$channels,
  );
  static DateTime? _$latestExportAt(TakeoutSummary v) => v.latestExportAt;
  static const Field<TakeoutSummary, DateTime> _f$latestExportAt = Field(
    'latestExportAt',
    _$latestExportAt,
    opt: true,
  );
  static bool _$countsKnown(TakeoutSummary v) => v.countsKnown;
  static const Field<TakeoutSummary, bool> _f$countsKnown = Field(
    'countsKnown',
    _$countsKnown,
  );

  @override
  final MappableFields<TakeoutSummary> fields = const {
    #id: _f$id,
    #channels: _f$channels,
    #latestExportAt: _f$latestExportAt,
    #countsKnown: _f$countsKnown,
  };

  static TakeoutSummary _instantiate(DecodingData data) {
    return TakeoutSummary(
      id: data.dec(_f$id),
      channels: data.dec(_f$channels),
      latestExportAt: data.dec(_f$latestExportAt),
      countsKnown: data.dec(_f$countsKnown),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static TakeoutSummary fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<TakeoutSummary>(map);
  }

  static TakeoutSummary fromJson(String json) {
    return ensureInitialized().decodeJson<TakeoutSummary>(json);
  }
}

mixin TakeoutSummaryMappable {
  String toJson() {
    return TakeoutSummaryMapper.ensureInitialized().encodeJson<TakeoutSummary>(
      this as TakeoutSummary,
    );
  }

  Map<String, dynamic> toMap() {
    return TakeoutSummaryMapper.ensureInitialized().encodeMap<TakeoutSummary>(
      this as TakeoutSummary,
    );
  }

  TakeoutSummaryCopyWith<TakeoutSummary, TakeoutSummary, TakeoutSummary>
  get copyWith => _TakeoutSummaryCopyWithImpl<TakeoutSummary, TakeoutSummary>(
    this as TakeoutSummary,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return TakeoutSummaryMapper.ensureInitialized().stringifyValue(
      this as TakeoutSummary,
    );
  }

  @override
  bool operator ==(Object other) {
    return TakeoutSummaryMapper.ensureInitialized().equalsValue(
      this as TakeoutSummary,
      other,
    );
  }

  @override
  int get hashCode {
    return TakeoutSummaryMapper.ensureInitialized().hashValue(
      this as TakeoutSummary,
    );
  }
}

extension TakeoutSummaryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, TakeoutSummary, $Out> {
  TakeoutSummaryCopyWith<$R, TakeoutSummary, $Out> get $asTakeoutSummary =>
      $base.as((v, t, t2) => _TakeoutSummaryCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class TakeoutSummaryCopyWith<$R, $In extends TakeoutSummary, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    TakeoutChannel,
    TakeoutChannelCopyWith<$R, TakeoutChannel, TakeoutChannel>
  >
  get channels;
  $R call({
    String? id,
    List<TakeoutChannel>? channels,
    DateTime? latestExportAt,
    bool? countsKnown,
  });
  TakeoutSummaryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _TakeoutSummaryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, TakeoutSummary, $Out>
    implements TakeoutSummaryCopyWith<$R, TakeoutSummary, $Out> {
  _TakeoutSummaryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<TakeoutSummary> $mapper =
      TakeoutSummaryMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    TakeoutChannel,
    TakeoutChannelCopyWith<$R, TakeoutChannel, TakeoutChannel>
  >
  get channels => ListCopyWith(
    $value.channels,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(channels: v),
  );
  @override
  $R call({
    String? id,
    List<TakeoutChannel>? channels,
    Object? latestExportAt = $none,
    bool? countsKnown,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (channels != null) #channels: channels,
      if (latestExportAt != $none) #latestExportAt: latestExportAt,
      if (countsKnown != null) #countsKnown: countsKnown,
    }),
  );
  @override
  TakeoutSummary $make(CopyWithData data) => TakeoutSummary(
    id: data.get(#id, or: $value.id),
    channels: data.get(#channels, or: $value.channels),
    latestExportAt: data.get(#latestExportAt, or: $value.latestExportAt),
    countsKnown: data.get(#countsKnown, or: $value.countsKnown),
  );

  @override
  TakeoutSummaryCopyWith<$R2, TakeoutSummary, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _TakeoutSummaryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

