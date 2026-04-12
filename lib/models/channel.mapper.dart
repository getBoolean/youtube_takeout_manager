// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'channel.dart';

class ChannelMapper extends ClassMapperBase<Channel> {
  ChannelMapper._();

  static ChannelMapper? _instance;
  static ChannelMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ChannelMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'Channel';

  static String _$channelId(Channel v) => v.channelId;
  static const Field<Channel, String> _f$channelId = Field(
    'channelId',
    _$channelId,
  );
  static String? _$channelTitle(Channel v) => v.channelTitle;
  static const Field<Channel, String> _f$channelTitle = Field(
    'channelTitle',
    _$channelTitle,
    opt: true,
  );
  static String? _$channelUrl(Channel v) => v.channelUrl;
  static const Field<Channel, String> _f$channelUrl = Field(
    'channelUrl',
    _$channelUrl,
    opt: true,
  );
  static int _$commentCount(Channel v) => v.commentCount;
  static const Field<Channel, int> _f$commentCount = Field(
    'commentCount',
    _$commentCount,
  );
  static int _$liveChatCount(Channel v) => v.liveChatCount;
  static const Field<Channel, int> _f$liveChatCount = Field(
    'liveChatCount',
    _$liveChatCount,
  );

  @override
  final MappableFields<Channel> fields = const {
    #channelId: _f$channelId,
    #channelTitle: _f$channelTitle,
    #channelUrl: _f$channelUrl,
    #commentCount: _f$commentCount,
    #liveChatCount: _f$liveChatCount,
  };

  static Channel _instantiate(DecodingData data) {
    return Channel(
      channelId: data.dec(_f$channelId),
      channelTitle: data.dec(_f$channelTitle),
      channelUrl: data.dec(_f$channelUrl),
      commentCount: data.dec(_f$commentCount),
      liveChatCount: data.dec(_f$liveChatCount),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Channel fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Channel>(map);
  }

  static Channel fromJson(String json) {
    return ensureInitialized().decodeJson<Channel>(json);
  }
}

mixin ChannelMappable {
  String toJson() {
    return ChannelMapper.ensureInitialized().encodeJson<Channel>(
      this as Channel,
    );
  }

  Map<String, dynamic> toMap() {
    return ChannelMapper.ensureInitialized().encodeMap<Channel>(
      this as Channel,
    );
  }

  ChannelCopyWith<Channel, Channel, Channel> get copyWith =>
      _ChannelCopyWithImpl<Channel, Channel>(
        this as Channel,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ChannelMapper.ensureInitialized().stringifyValue(this as Channel);
  }

  @override
  bool operator ==(Object other) {
    return ChannelMapper.ensureInitialized().equalsValue(
      this as Channel,
      other,
    );
  }

  @override
  int get hashCode {
    return ChannelMapper.ensureInitialized().hashValue(this as Channel);
  }
}

extension ChannelValueCopy<$R, $Out> on ObjectCopyWith<$R, Channel, $Out> {
  ChannelCopyWith<$R, Channel, $Out> get $asChannel =>
      $base.as((v, t, t2) => _ChannelCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ChannelCopyWith<$R, $In extends Channel, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? channelId,
    String? channelTitle,
    String? channelUrl,
    int? commentCount,
    int? liveChatCount,
  });
  ChannelCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ChannelCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Channel, $Out>
    implements ChannelCopyWith<$R, Channel, $Out> {
  _ChannelCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Channel> $mapper =
      ChannelMapper.ensureInitialized();
  @override
  $R call({
    String? channelId,
    Object? channelTitle = $none,
    Object? channelUrl = $none,
    int? commentCount,
    int? liveChatCount,
  }) => $apply(
    FieldCopyWithData({
      if (channelId != null) #channelId: channelId,
      if (channelTitle != $none) #channelTitle: channelTitle,
      if (channelUrl != $none) #channelUrl: channelUrl,
      if (commentCount != null) #commentCount: commentCount,
      if (liveChatCount != null) #liveChatCount: liveChatCount,
    }),
  );
  @override
  Channel $make(CopyWithData data) => Channel(
    channelId: data.get(#channelId, or: $value.channelId),
    channelTitle: data.get(#channelTitle, or: $value.channelTitle),
    channelUrl: data.get(#channelUrl, or: $value.channelUrl),
    commentCount: data.get(#commentCount, or: $value.commentCount),
    liveChatCount: data.get(#liveChatCount, or: $value.liveChatCount),
  );

  @override
  ChannelCopyWith<$R2, Channel, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ChannelCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

