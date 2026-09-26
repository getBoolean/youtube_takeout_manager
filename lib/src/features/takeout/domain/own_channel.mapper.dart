// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'own_channel.dart';

class OwnChannelMapper extends ClassMapperBase<OwnChannel> {
  OwnChannelMapper._();

  static OwnChannelMapper? _instance;
  static OwnChannelMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = OwnChannelMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'OwnChannel';

  static String _$channelId(OwnChannel v) => v.channelId;
  static const Field<OwnChannel, String> _f$channelId = Field(
    'channelId',
    _$channelId,
  );
  static String? _$title(OwnChannel v) => v.title;
  static const Field<OwnChannel, String> _f$title = Field(
    'title',
    _$title,
    opt: true,
  );
  static String? _$vanityName(OwnChannel v) => v.vanityName;
  static const Field<OwnChannel, String> _f$vanityName = Field(
    'vanityName',
    _$vanityName,
    opt: true,
  );

  @override
  final MappableFields<OwnChannel> fields = const {
    #channelId: _f$channelId,
    #title: _f$title,
    #vanityName: _f$vanityName,
  };

  static OwnChannel _instantiate(DecodingData data) {
    return OwnChannel(
      channelId: data.dec(_f$channelId),
      title: data.dec(_f$title),
      vanityName: data.dec(_f$vanityName),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static OwnChannel fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<OwnChannel>(map);
  }

  static OwnChannel fromJson(String json) {
    return ensureInitialized().decodeJson<OwnChannel>(json);
  }
}

mixin OwnChannelMappable {
  String toJson() {
    return OwnChannelMapper.ensureInitialized().encodeJson<OwnChannel>(
      this as OwnChannel,
    );
  }

  Map<String, dynamic> toMap() {
    return OwnChannelMapper.ensureInitialized().encodeMap<OwnChannel>(
      this as OwnChannel,
    );
  }

  OwnChannelCopyWith<OwnChannel, OwnChannel, OwnChannel> get copyWith =>
      _OwnChannelCopyWithImpl<OwnChannel, OwnChannel>(
        this as OwnChannel,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return OwnChannelMapper.ensureInitialized().stringifyValue(
      this as OwnChannel,
    );
  }

  @override
  bool operator ==(Object other) {
    return OwnChannelMapper.ensureInitialized().equalsValue(
      this as OwnChannel,
      other,
    );
  }

  @override
  int get hashCode {
    return OwnChannelMapper.ensureInitialized().hashValue(this as OwnChannel);
  }
}

extension OwnChannelValueCopy<$R, $Out>
    on ObjectCopyWith<$R, OwnChannel, $Out> {
  OwnChannelCopyWith<$R, OwnChannel, $Out> get $asOwnChannel =>
      $base.as((v, t, t2) => _OwnChannelCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class OwnChannelCopyWith<$R, $In extends OwnChannel, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? channelId, String? title, String? vanityName});
  OwnChannelCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _OwnChannelCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, OwnChannel, $Out>
    implements OwnChannelCopyWith<$R, OwnChannel, $Out> {
  _OwnChannelCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<OwnChannel> $mapper =
      OwnChannelMapper.ensureInitialized();
  @override
  $R call({
    String? channelId,
    Object? title = $none,
    Object? vanityName = $none,
  }) => $apply(
    FieldCopyWithData({
      if (channelId != null) #channelId: channelId,
      if (title != $none) #title: title,
      if (vanityName != $none) #vanityName: vanityName,
    }),
  );
  @override
  OwnChannel $make(CopyWithData data) => OwnChannel(
    channelId: data.get(#channelId, or: $value.channelId),
    title: data.get(#title, or: $value.title),
    vanityName: data.get(#vanityName, or: $value.vanityName),
  );

  @override
  OwnChannelCopyWith<$R2, OwnChannel, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _OwnChannelCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

