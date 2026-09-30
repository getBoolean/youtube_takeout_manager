// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'oauth_client.dart';

class OAuthClientMapper extends ClassMapperBase<OAuthClient> {
  OAuthClientMapper._();

  static OAuthClientMapper? _instance;
  static OAuthClientMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = OAuthClientMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'OAuthClient';

  static String _$id(OAuthClient v) => v.id;
  static const Field<OAuthClient, String> _f$id = Field('id', _$id);
  static String? _$secret(OAuthClient v) => v.secret;
  static const Field<OAuthClient, String> _f$secret = Field(
    'secret',
    _$secret,
    opt: true,
  );

  @override
  final MappableFields<OAuthClient> fields = const {
    #id: _f$id,
    #secret: _f$secret,
  };

  static OAuthClient _instantiate(DecodingData data) {
    return OAuthClient(id: data.dec(_f$id), secret: data.dec(_f$secret));
  }

  @override
  final Function instantiate = _instantiate;

  static OAuthClient fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<OAuthClient>(map);
  }

  static OAuthClient fromJson(String json) {
    return ensureInitialized().decodeJson<OAuthClient>(json);
  }
}

mixin OAuthClientMappable {
  String toJson() {
    return OAuthClientMapper.ensureInitialized().encodeJson<OAuthClient>(
      this as OAuthClient,
    );
  }

  Map<String, dynamic> toMap() {
    return OAuthClientMapper.ensureInitialized().encodeMap<OAuthClient>(
      this as OAuthClient,
    );
  }

  OAuthClientCopyWith<OAuthClient, OAuthClient, OAuthClient> get copyWith =>
      _OAuthClientCopyWithImpl<OAuthClient, OAuthClient>(
        this as OAuthClient,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return OAuthClientMapper.ensureInitialized().stringifyValue(
      this as OAuthClient,
    );
  }

  @override
  bool operator ==(Object other) {
    return OAuthClientMapper.ensureInitialized().equalsValue(
      this as OAuthClient,
      other,
    );
  }

  @override
  int get hashCode {
    return OAuthClientMapper.ensureInitialized().hashValue(this as OAuthClient);
  }
}

extension OAuthClientValueCopy<$R, $Out>
    on ObjectCopyWith<$R, OAuthClient, $Out> {
  OAuthClientCopyWith<$R, OAuthClient, $Out> get $asOAuthClient =>
      $base.as((v, t, t2) => _OAuthClientCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class OAuthClientCopyWith<$R, $In extends OAuthClient, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? id, String? secret});
  OAuthClientCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _OAuthClientCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, OAuthClient, $Out>
    implements OAuthClientCopyWith<$R, OAuthClient, $Out> {
  _OAuthClientCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<OAuthClient> $mapper =
      OAuthClientMapper.ensureInitialized();
  @override
  $R call({String? id, Object? secret = $none}) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (secret != $none) #secret: secret,
    }),
  );
  @override
  OAuthClient $make(CopyWithData data) => OAuthClient(
    id: data.get(#id, or: $value.id),
    secret: data.get(#secret, or: $value.secret),
  );

  @override
  OAuthClientCopyWith<$R2, OAuthClient, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _OAuthClientCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

