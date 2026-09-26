// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'auth_state.dart';

class AuthStateMapper extends ClassMapperBase<AuthState> {
  AuthStateMapper._();

  static AuthStateMapper? _instance;
  static AuthStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = AuthStateMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'AuthState';

  static String _$channelId(AuthState v) => v.channelId;
  static const Field<AuthState, String> _f$channelId = Field(
    'channelId',
    _$channelId,
  );
  static String? _$channelTitle(AuthState v) => v.channelTitle;
  static const Field<AuthState, String> _f$channelTitle = Field(
    'channelTitle',
    _$channelTitle,
    opt: true,
  );
  static String? _$channelThumbnailUrl(AuthState v) => v.channelThumbnailUrl;
  static const Field<AuthState, String> _f$channelThumbnailUrl = Field(
    'channelThumbnailUrl',
    _$channelThumbnailUrl,
    opt: true,
  );
  static String? _$displayName(AuthState v) => v.displayName;
  static const Field<AuthState, String> _f$displayName = Field(
    'displayName',
    _$displayName,
    opt: true,
  );
  static String? _$email(AuthState v) => v.email;
  static const Field<AuthState, String> _f$email = Field(
    'email',
    _$email,
    opt: true,
  );
  static String? _$photoUrl(AuthState v) => v.photoUrl;
  static const Field<AuthState, String> _f$photoUrl = Field(
    'photoUrl',
    _$photoUrl,
    opt: true,
  );

  @override
  final MappableFields<AuthState> fields = const {
    #channelId: _f$channelId,
    #channelTitle: _f$channelTitle,
    #channelThumbnailUrl: _f$channelThumbnailUrl,
    #displayName: _f$displayName,
    #email: _f$email,
    #photoUrl: _f$photoUrl,
  };

  static AuthState _instantiate(DecodingData data) {
    return AuthState(
      channelId: data.dec(_f$channelId),
      channelTitle: data.dec(_f$channelTitle),
      channelThumbnailUrl: data.dec(_f$channelThumbnailUrl),
      displayName: data.dec(_f$displayName),
      email: data.dec(_f$email),
      photoUrl: data.dec(_f$photoUrl),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static AuthState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<AuthState>(map);
  }

  static AuthState fromJson(String json) {
    return ensureInitialized().decodeJson<AuthState>(json);
  }
}

mixin AuthStateMappable {
  String toJson() {
    return AuthStateMapper.ensureInitialized().encodeJson<AuthState>(
      this as AuthState,
    );
  }

  Map<String, dynamic> toMap() {
    return AuthStateMapper.ensureInitialized().encodeMap<AuthState>(
      this as AuthState,
    );
  }

  AuthStateCopyWith<AuthState, AuthState, AuthState> get copyWith =>
      _AuthStateCopyWithImpl<AuthState, AuthState>(
        this as AuthState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return AuthStateMapper.ensureInitialized().stringifyValue(
      this as AuthState,
    );
  }

  @override
  bool operator ==(Object other) {
    return AuthStateMapper.ensureInitialized().equalsValue(
      this as AuthState,
      other,
    );
  }

  @override
  int get hashCode {
    return AuthStateMapper.ensureInitialized().hashValue(this as AuthState);
  }
}

extension AuthStateValueCopy<$R, $Out> on ObjectCopyWith<$R, AuthState, $Out> {
  AuthStateCopyWith<$R, AuthState, $Out> get $asAuthState =>
      $base.as((v, t, t2) => _AuthStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class AuthStateCopyWith<$R, $In extends AuthState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? channelId,
    String? channelTitle,
    String? channelThumbnailUrl,
    String? displayName,
    String? email,
    String? photoUrl,
  });
  AuthStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _AuthStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, AuthState, $Out>
    implements AuthStateCopyWith<$R, AuthState, $Out> {
  _AuthStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<AuthState> $mapper =
      AuthStateMapper.ensureInitialized();
  @override
  $R call({
    String? channelId,
    Object? channelTitle = $none,
    Object? channelThumbnailUrl = $none,
    Object? displayName = $none,
    Object? email = $none,
    Object? photoUrl = $none,
  }) => $apply(
    FieldCopyWithData({
      if (channelId != null) #channelId: channelId,
      if (channelTitle != $none) #channelTitle: channelTitle,
      if (channelThumbnailUrl != $none)
        #channelThumbnailUrl: channelThumbnailUrl,
      if (displayName != $none) #displayName: displayName,
      if (email != $none) #email: email,
      if (photoUrl != $none) #photoUrl: photoUrl,
    }),
  );
  @override
  AuthState $make(CopyWithData data) => AuthState(
    channelId: data.get(#channelId, or: $value.channelId),
    channelTitle: data.get(#channelTitle, or: $value.channelTitle),
    channelThumbnailUrl: data.get(
      #channelThumbnailUrl,
      or: $value.channelThumbnailUrl,
    ),
    displayName: data.get(#displayName, or: $value.displayName),
    email: data.get(#email, or: $value.email),
    photoUrl: data.get(#photoUrl, or: $value.photoUrl),
  );

  @override
  AuthStateCopyWith<$R2, AuthState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _AuthStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

