// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'watched_channels.dart';

class HistoryChannelMapper extends ClassMapperBase<HistoryChannel> {
  HistoryChannelMapper._();

  static HistoryChannelMapper? _instance;
  static HistoryChannelMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = HistoryChannelMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'HistoryChannel';

  static String? _$channelId(HistoryChannel v) => v.channelId;
  static const Field<HistoryChannel, String> _f$channelId = Field(
    'channelId',
    _$channelId,
    opt: true,
  );
  static String _$title(HistoryChannel v) => v.title;
  static const Field<HistoryChannel, String> _f$title = Field('title', _$title);
  static String? _$channelUrl(HistoryChannel v) => v.channelUrl;
  static const Field<HistoryChannel, String> _f$channelUrl = Field(
    'channelUrl',
    _$channelUrl,
    opt: true,
  );

  @override
  final MappableFields<HistoryChannel> fields = const {
    #channelId: _f$channelId,
    #title: _f$title,
    #channelUrl: _f$channelUrl,
  };

  static HistoryChannel _instantiate(DecodingData data) {
    return HistoryChannel(
      channelId: data.dec(_f$channelId),
      title: data.dec(_f$title),
      channelUrl: data.dec(_f$channelUrl),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static HistoryChannel fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<HistoryChannel>(map);
  }

  static HistoryChannel fromJson(String json) {
    return ensureInitialized().decodeJson<HistoryChannel>(json);
  }
}

mixin HistoryChannelMappable {
  String toJson() {
    return HistoryChannelMapper.ensureInitialized().encodeJson<HistoryChannel>(
      this as HistoryChannel,
    );
  }

  Map<String, dynamic> toMap() {
    return HistoryChannelMapper.ensureInitialized().encodeMap<HistoryChannel>(
      this as HistoryChannel,
    );
  }

  HistoryChannelCopyWith<HistoryChannel, HistoryChannel, HistoryChannel>
  get copyWith => _HistoryChannelCopyWithImpl<HistoryChannel, HistoryChannel>(
    this as HistoryChannel,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return HistoryChannelMapper.ensureInitialized().stringifyValue(
      this as HistoryChannel,
    );
  }

  @override
  bool operator ==(Object other) {
    return HistoryChannelMapper.ensureInitialized().equalsValue(
      this as HistoryChannel,
      other,
    );
  }

  @override
  int get hashCode {
    return HistoryChannelMapper.ensureInitialized().hashValue(
      this as HistoryChannel,
    );
  }
}

extension HistoryChannelValueCopy<$R, $Out>
    on ObjectCopyWith<$R, HistoryChannel, $Out> {
  HistoryChannelCopyWith<$R, HistoryChannel, $Out> get $asHistoryChannel =>
      $base.as((v, t, t2) => _HistoryChannelCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class HistoryChannelCopyWith<$R, $In extends HistoryChannel, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? channelId, String? title, String? channelUrl});
  HistoryChannelCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _HistoryChannelCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, HistoryChannel, $Out>
    implements HistoryChannelCopyWith<$R, HistoryChannel, $Out> {
  _HistoryChannelCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<HistoryChannel> $mapper =
      HistoryChannelMapper.ensureInitialized();
  @override
  $R call({
    Object? channelId = $none,
    String? title,
    Object? channelUrl = $none,
  }) => $apply(
    FieldCopyWithData({
      if (channelId != $none) #channelId: channelId,
      if (title != null) #title: title,
      if (channelUrl != $none) #channelUrl: channelUrl,
    }),
  );
  @override
  HistoryChannel $make(CopyWithData data) => HistoryChannel(
    channelId: data.get(#channelId, or: $value.channelId),
    title: data.get(#title, or: $value.title),
    channelUrl: data.get(#channelUrl, or: $value.channelUrl),
  );

  @override
  HistoryChannelCopyWith<$R2, HistoryChannel, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _HistoryChannelCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

