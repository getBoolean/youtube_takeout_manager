// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'sign_in_profile.dart';

class SignInProfileMapper extends ClassMapperBase<SignInProfile> {
  SignInProfileMapper._();

  static SignInProfileMapper? _instance;
  static SignInProfileMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SignInProfileMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'SignInProfile';

  static String _$channelId(SignInProfile v) => v.channelId;
  static const Field<SignInProfile, String> _f$channelId = Field(
    'channelId',
    _$channelId,
  );
  static String? _$channelTitle(SignInProfile v) => v.channelTitle;
  static const Field<SignInProfile, String> _f$channelTitle = Field(
    'channelTitle',
    _$channelTitle,
    opt: true,
  );
  static String? _$channelHandle(SignInProfile v) => v.channelHandle;
  static const Field<SignInProfile, String> _f$channelHandle = Field(
    'channelHandle',
    _$channelHandle,
    opt: true,
  );
  static String? _$channelThumbnailUrl(SignInProfile v) =>
      v.channelThumbnailUrl;
  static const Field<SignInProfile, String> _f$channelThumbnailUrl = Field(
    'channelThumbnailUrl',
    _$channelThumbnailUrl,
    opt: true,
  );
  static String? _$displayName(SignInProfile v) => v.displayName;
  static const Field<SignInProfile, String> _f$displayName = Field(
    'displayName',
    _$displayName,
    opt: true,
  );
  static String? _$email(SignInProfile v) => v.email;
  static const Field<SignInProfile, String> _f$email = Field(
    'email',
    _$email,
    opt: true,
  );
  static String? _$photoUrl(SignInProfile v) => v.photoUrl;
  static const Field<SignInProfile, String> _f$photoUrl = Field(
    'photoUrl',
    _$photoUrl,
    opt: true,
  );

  @override
  final MappableFields<SignInProfile> fields = const {
    #channelId: _f$channelId,
    #channelTitle: _f$channelTitle,
    #channelHandle: _f$channelHandle,
    #channelThumbnailUrl: _f$channelThumbnailUrl,
    #displayName: _f$displayName,
    #email: _f$email,
    #photoUrl: _f$photoUrl,
  };

  static SignInProfile _instantiate(DecodingData data) {
    return SignInProfile(
      channelId: data.dec(_f$channelId),
      channelTitle: data.dec(_f$channelTitle),
      channelHandle: data.dec(_f$channelHandle),
      channelThumbnailUrl: data.dec(_f$channelThumbnailUrl),
      displayName: data.dec(_f$displayName),
      email: data.dec(_f$email),
      photoUrl: data.dec(_f$photoUrl),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SignInProfile fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SignInProfile>(map);
  }

  static SignInProfile fromJson(String json) {
    return ensureInitialized().decodeJson<SignInProfile>(json);
  }
}

mixin SignInProfileMappable {
  String toJson() {
    return SignInProfileMapper.ensureInitialized().encodeJson<SignInProfile>(
      this as SignInProfile,
    );
  }

  Map<String, dynamic> toMap() {
    return SignInProfileMapper.ensureInitialized().encodeMap<SignInProfile>(
      this as SignInProfile,
    );
  }

  SignInProfileCopyWith<SignInProfile, SignInProfile, SignInProfile>
  get copyWith => _SignInProfileCopyWithImpl<SignInProfile, SignInProfile>(
    this as SignInProfile,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return SignInProfileMapper.ensureInitialized().stringifyValue(
      this as SignInProfile,
    );
  }

  @override
  bool operator ==(Object other) {
    return SignInProfileMapper.ensureInitialized().equalsValue(
      this as SignInProfile,
      other,
    );
  }

  @override
  int get hashCode {
    return SignInProfileMapper.ensureInitialized().hashValue(
      this as SignInProfile,
    );
  }
}

extension SignInProfileValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SignInProfile, $Out> {
  SignInProfileCopyWith<$R, SignInProfile, $Out> get $asSignInProfile =>
      $base.as((v, t, t2) => _SignInProfileCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SignInProfileCopyWith<$R, $In extends SignInProfile, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? channelId,
    String? channelTitle,
    String? channelHandle,
    String? channelThumbnailUrl,
    String? displayName,
    String? email,
    String? photoUrl,
  });
  SignInProfileCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SignInProfileCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SignInProfile, $Out>
    implements SignInProfileCopyWith<$R, SignInProfile, $Out> {
  _SignInProfileCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SignInProfile> $mapper =
      SignInProfileMapper.ensureInitialized();
  @override
  $R call({
    String? channelId,
    Object? channelTitle = $none,
    Object? channelHandle = $none,
    Object? channelThumbnailUrl = $none,
    Object? displayName = $none,
    Object? email = $none,
    Object? photoUrl = $none,
  }) => $apply(
    FieldCopyWithData({
      if (channelId != null) #channelId: channelId,
      if (channelTitle != $none) #channelTitle: channelTitle,
      if (channelHandle != $none) #channelHandle: channelHandle,
      if (channelThumbnailUrl != $none)
        #channelThumbnailUrl: channelThumbnailUrl,
      if (displayName != $none) #displayName: displayName,
      if (email != $none) #email: email,
      if (photoUrl != $none) #photoUrl: photoUrl,
    }),
  );
  @override
  SignInProfile $make(CopyWithData data) => SignInProfile(
    channelId: data.get(#channelId, or: $value.channelId),
    channelTitle: data.get(#channelTitle, or: $value.channelTitle),
    channelHandle: data.get(#channelHandle, or: $value.channelHandle),
    channelThumbnailUrl: data.get(
      #channelThumbnailUrl,
      or: $value.channelThumbnailUrl,
    ),
    displayName: data.get(#displayName, or: $value.displayName),
    email: data.get(#email, or: $value.email),
    photoUrl: data.get(#photoUrl, or: $value.photoUrl),
  );

  @override
  SignInProfileCopyWith<$R2, SignInProfile, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SignInProfileCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

