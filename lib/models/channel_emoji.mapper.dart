// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'channel_emoji.dart';

class ChannelEmojiMapper extends ClassMapperBase<ChannelEmoji> {
  ChannelEmojiMapper._();

  static ChannelEmojiMapper? _instance;
  static ChannelEmojiMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ChannelEmojiMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ChannelEmoji';

  static String _$key(ChannelEmoji v) => v.key;
  static const Field<ChannelEmoji, String> _f$key = Field('key', _$key);
  static String _$url(ChannelEmoji v) => v.url;
  static const Field<ChannelEmoji, String> _f$url = Field('url', _$url);
  static String _$name(ChannelEmoji v) => v.name;
  static const Field<ChannelEmoji, String> _f$name = Field('name', _$name);
  static String _$channelId(ChannelEmoji v) => v.channelId;
  static const Field<ChannelEmoji, String> _f$channelId = Field(
    'channelId',
    _$channelId,
  );
  static int _$usageCount(ChannelEmoji v) => v.usageCount;
  static const Field<ChannelEmoji, int> _f$usageCount = Field(
    'usageCount',
    _$usageCount,
  );
  static bool _$resolved(ChannelEmoji v) => v.resolved;
  static const Field<ChannelEmoji, bool> _f$resolved = Field(
    'resolved',
    _$resolved,
  );

  @override
  final MappableFields<ChannelEmoji> fields = const {
    #key: _f$key,
    #url: _f$url,
    #name: _f$name,
    #channelId: _f$channelId,
    #usageCount: _f$usageCount,
    #resolved: _f$resolved,
  };

  static ChannelEmoji _instantiate(DecodingData data) {
    return ChannelEmoji(
      key: data.dec(_f$key),
      url: data.dec(_f$url),
      name: data.dec(_f$name),
      channelId: data.dec(_f$channelId),
      usageCount: data.dec(_f$usageCount),
      resolved: data.dec(_f$resolved),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ChannelEmoji fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ChannelEmoji>(map);
  }

  static ChannelEmoji fromJson(String json) {
    return ensureInitialized().decodeJson<ChannelEmoji>(json);
  }
}

mixin ChannelEmojiMappable {
  String toJson() {
    return ChannelEmojiMapper.ensureInitialized().encodeJson<ChannelEmoji>(
      this as ChannelEmoji,
    );
  }

  Map<String, dynamic> toMap() {
    return ChannelEmojiMapper.ensureInitialized().encodeMap<ChannelEmoji>(
      this as ChannelEmoji,
    );
  }

  ChannelEmojiCopyWith<ChannelEmoji, ChannelEmoji, ChannelEmoji> get copyWith =>
      _ChannelEmojiCopyWithImpl<ChannelEmoji, ChannelEmoji>(
        this as ChannelEmoji,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ChannelEmojiMapper.ensureInitialized().stringifyValue(
      this as ChannelEmoji,
    );
  }

  @override
  bool operator ==(Object other) {
    return ChannelEmojiMapper.ensureInitialized().equalsValue(
      this as ChannelEmoji,
      other,
    );
  }

  @override
  int get hashCode {
    return ChannelEmojiMapper.ensureInitialized().hashValue(
      this as ChannelEmoji,
    );
  }
}

extension ChannelEmojiValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ChannelEmoji, $Out> {
  ChannelEmojiCopyWith<$R, ChannelEmoji, $Out> get $asChannelEmoji =>
      $base.as((v, t, t2) => _ChannelEmojiCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ChannelEmojiCopyWith<$R, $In extends ChannelEmoji, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? key,
    String? url,
    String? name,
    String? channelId,
    int? usageCount,
    bool? resolved,
  });
  ChannelEmojiCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ChannelEmojiCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ChannelEmoji, $Out>
    implements ChannelEmojiCopyWith<$R, ChannelEmoji, $Out> {
  _ChannelEmojiCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ChannelEmoji> $mapper =
      ChannelEmojiMapper.ensureInitialized();
  @override
  $R call({
    String? key,
    String? url,
    String? name,
    String? channelId,
    int? usageCount,
    bool? resolved,
  }) => $apply(
    FieldCopyWithData({
      if (key != null) #key: key,
      if (url != null) #url: url,
      if (name != null) #name: name,
      if (channelId != null) #channelId: channelId,
      if (usageCount != null) #usageCount: usageCount,
      if (resolved != null) #resolved: resolved,
    }),
  );
  @override
  ChannelEmoji $make(CopyWithData data) => ChannelEmoji(
    key: data.get(#key, or: $value.key),
    url: data.get(#url, or: $value.url),
    name: data.get(#name, or: $value.name),
    channelId: data.get(#channelId, or: $value.channelId),
    usageCount: data.get(#usageCount, or: $value.usageCount),
    resolved: data.get(#resolved, or: $value.resolved),
  );

  @override
  ChannelEmojiCopyWith<$R2, ChannelEmoji, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ChannelEmojiCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ChannelEmojiGroupMapper extends ClassMapperBase<ChannelEmojiGroup> {
  ChannelEmojiGroupMapper._();

  static ChannelEmojiGroupMapper? _instance;
  static ChannelEmojiGroupMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ChannelEmojiGroupMapper._());
      ChannelEmojiMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ChannelEmojiGroup';

  static String _$channelId(ChannelEmojiGroup v) => v.channelId;
  static const Field<ChannelEmojiGroup, String> _f$channelId = Field(
    'channelId',
    _$channelId,
  );
  static String? _$channelTitle(ChannelEmojiGroup v) => v.channelTitle;
  static const Field<ChannelEmojiGroup, String> _f$channelTitle = Field(
    'channelTitle',
    _$channelTitle,
    opt: true,
  );
  static String? _$thumbnailUrl(ChannelEmojiGroup v) => v.thumbnailUrl;
  static const Field<ChannelEmojiGroup, String> _f$thumbnailUrl = Field(
    'thumbnailUrl',
    _$thumbnailUrl,
    opt: true,
  );
  static List<ChannelEmoji> _$emojis(ChannelEmojiGroup v) => v.emojis;
  static const Field<ChannelEmojiGroup, List<ChannelEmoji>> _f$emojis = Field(
    'emojis',
    _$emojis,
  );

  @override
  final MappableFields<ChannelEmojiGroup> fields = const {
    #channelId: _f$channelId,
    #channelTitle: _f$channelTitle,
    #thumbnailUrl: _f$thumbnailUrl,
    #emojis: _f$emojis,
  };

  static ChannelEmojiGroup _instantiate(DecodingData data) {
    return ChannelEmojiGroup(
      channelId: data.dec(_f$channelId),
      channelTitle: data.dec(_f$channelTitle),
      thumbnailUrl: data.dec(_f$thumbnailUrl),
      emojis: data.dec(_f$emojis),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ChannelEmojiGroup fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ChannelEmojiGroup>(map);
  }

  static ChannelEmojiGroup fromJson(String json) {
    return ensureInitialized().decodeJson<ChannelEmojiGroup>(json);
  }
}

mixin ChannelEmojiGroupMappable {
  String toJson() {
    return ChannelEmojiGroupMapper.ensureInitialized()
        .encodeJson<ChannelEmojiGroup>(this as ChannelEmojiGroup);
  }

  Map<String, dynamic> toMap() {
    return ChannelEmojiGroupMapper.ensureInitialized()
        .encodeMap<ChannelEmojiGroup>(this as ChannelEmojiGroup);
  }

  ChannelEmojiGroupCopyWith<
    ChannelEmojiGroup,
    ChannelEmojiGroup,
    ChannelEmojiGroup
  >
  get copyWith =>
      _ChannelEmojiGroupCopyWithImpl<ChannelEmojiGroup, ChannelEmojiGroup>(
        this as ChannelEmojiGroup,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ChannelEmojiGroupMapper.ensureInitialized().stringifyValue(
      this as ChannelEmojiGroup,
    );
  }

  @override
  bool operator ==(Object other) {
    return ChannelEmojiGroupMapper.ensureInitialized().equalsValue(
      this as ChannelEmojiGroup,
      other,
    );
  }

  @override
  int get hashCode {
    return ChannelEmojiGroupMapper.ensureInitialized().hashValue(
      this as ChannelEmojiGroup,
    );
  }
}

extension ChannelEmojiGroupValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ChannelEmojiGroup, $Out> {
  ChannelEmojiGroupCopyWith<$R, ChannelEmojiGroup, $Out>
  get $asChannelEmojiGroup => $base.as(
    (v, t, t2) => _ChannelEmojiGroupCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ChannelEmojiGroupCopyWith<
  $R,
  $In extends ChannelEmojiGroup,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    ChannelEmoji,
    ChannelEmojiCopyWith<$R, ChannelEmoji, ChannelEmoji>
  >
  get emojis;
  $R call({
    String? channelId,
    String? channelTitle,
    String? thumbnailUrl,
    List<ChannelEmoji>? emojis,
  });
  ChannelEmojiGroupCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ChannelEmojiGroupCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ChannelEmojiGroup, $Out>
    implements ChannelEmojiGroupCopyWith<$R, ChannelEmojiGroup, $Out> {
  _ChannelEmojiGroupCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ChannelEmojiGroup> $mapper =
      ChannelEmojiGroupMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    ChannelEmoji,
    ChannelEmojiCopyWith<$R, ChannelEmoji, ChannelEmoji>
  >
  get emojis => ListCopyWith(
    $value.emojis,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(emojis: v),
  );
  @override
  $R call({
    String? channelId,
    Object? channelTitle = $none,
    Object? thumbnailUrl = $none,
    List<ChannelEmoji>? emojis,
  }) => $apply(
    FieldCopyWithData({
      if (channelId != null) #channelId: channelId,
      if (channelTitle != $none) #channelTitle: channelTitle,
      if (thumbnailUrl != $none) #thumbnailUrl: thumbnailUrl,
      if (emojis != null) #emojis: emojis,
    }),
  );
  @override
  ChannelEmojiGroup $make(CopyWithData data) => ChannelEmojiGroup(
    channelId: data.get(#channelId, or: $value.channelId),
    channelTitle: data.get(#channelTitle, or: $value.channelTitle),
    thumbnailUrl: data.get(#thumbnailUrl, or: $value.thumbnailUrl),
    emojis: data.get(#emojis, or: $value.emojis),
  );

  @override
  ChannelEmojiGroupCopyWith<$R2, ChannelEmojiGroup, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ChannelEmojiGroupCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

