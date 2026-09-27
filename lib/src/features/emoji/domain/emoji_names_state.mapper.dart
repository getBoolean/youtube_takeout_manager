// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'emoji_names_state.dart';

class EmojiNamesStateMapper extends ClassMapperBase<EmojiNamesState> {
  EmojiNamesStateMapper._();

  static EmojiNamesStateMapper? _instance;
  static EmojiNamesStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = EmojiNamesStateMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'EmojiNamesState';

  static Map<String, ResolvedEmoji> _$names(EmojiNamesState v) => v.names;
  static const Field<EmojiNamesState, Map<String, ResolvedEmoji>> _f$names =
      Field('names', _$names, opt: true, def: const {});
  static bool _$isResolving(EmojiNamesState v) => v.isResolving;
  static const Field<EmojiNamesState, bool> _f$isResolving = Field(
    'isResolving',
    _$isResolving,
    opt: true,
    def: false,
  );
  static bool _$lookupUnavailable(EmojiNamesState v) => v.lookupUnavailable;
  static const Field<EmojiNamesState, bool> _f$lookupUnavailable = Field(
    'lookupUnavailable',
    _$lookupUnavailable,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<EmojiNamesState> fields = const {
    #names: _f$names,
    #isResolving: _f$isResolving,
    #lookupUnavailable: _f$lookupUnavailable,
  };

  static EmojiNamesState _instantiate(DecodingData data) {
    return EmojiNamesState(
      names: data.dec(_f$names),
      isResolving: data.dec(_f$isResolving),
      lookupUnavailable: data.dec(_f$lookupUnavailable),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static EmojiNamesState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<EmojiNamesState>(map);
  }

  static EmojiNamesState fromJson(String json) {
    return ensureInitialized().decodeJson<EmojiNamesState>(json);
  }
}

mixin EmojiNamesStateMappable {
  String toJson() {
    return EmojiNamesStateMapper.ensureInitialized()
        .encodeJson<EmojiNamesState>(this as EmojiNamesState);
  }

  Map<String, dynamic> toMap() {
    return EmojiNamesStateMapper.ensureInitialized().encodeMap<EmojiNamesState>(
      this as EmojiNamesState,
    );
  }

  EmojiNamesStateCopyWith<EmojiNamesState, EmojiNamesState, EmojiNamesState>
  get copyWith =>
      _EmojiNamesStateCopyWithImpl<EmojiNamesState, EmojiNamesState>(
        this as EmojiNamesState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return EmojiNamesStateMapper.ensureInitialized().stringifyValue(
      this as EmojiNamesState,
    );
  }

  @override
  bool operator ==(Object other) {
    return EmojiNamesStateMapper.ensureInitialized().equalsValue(
      this as EmojiNamesState,
      other,
    );
  }

  @override
  int get hashCode {
    return EmojiNamesStateMapper.ensureInitialized().hashValue(
      this as EmojiNamesState,
    );
  }
}

extension EmojiNamesStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, EmojiNamesState, $Out> {
  EmojiNamesStateCopyWith<$R, EmojiNamesState, $Out> get $asEmojiNamesState =>
      $base.as((v, t, t2) => _EmojiNamesStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class EmojiNamesStateCopyWith<$R, $In extends EmojiNamesState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<
    $R,
    String,
    ResolvedEmoji,
    ObjectCopyWith<$R, ResolvedEmoji, ResolvedEmoji>
  >
  get names;
  $R call({
    Map<String, ResolvedEmoji>? names,
    bool? isResolving,
    bool? lookupUnavailable,
  });
  EmojiNamesStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _EmojiNamesStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, EmojiNamesState, $Out>
    implements EmojiNamesStateCopyWith<$R, EmojiNamesState, $Out> {
  _EmojiNamesStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<EmojiNamesState> $mapper =
      EmojiNamesStateMapper.ensureInitialized();
  @override
  MapCopyWith<
    $R,
    String,
    ResolvedEmoji,
    ObjectCopyWith<$R, ResolvedEmoji, ResolvedEmoji>
  >
  get names => MapCopyWith(
    $value.names,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(names: v),
  );
  @override
  $R call({
    Map<String, ResolvedEmoji>? names,
    bool? isResolving,
    bool? lookupUnavailable,
  }) => $apply(
    FieldCopyWithData({
      if (names != null) #names: names,
      if (isResolving != null) #isResolving: isResolving,
      if (lookupUnavailable != null) #lookupUnavailable: lookupUnavailable,
    }),
  );
  @override
  EmojiNamesState $make(CopyWithData data) => EmojiNamesState(
    names: data.get(#names, or: $value.names),
    isResolving: data.get(#isResolving, or: $value.isResolving),
    lookupUnavailable: data.get(
      #lookupUnavailable,
      or: $value.lookupUnavailable,
    ),
  );

  @override
  EmojiNamesStateCopyWith<$R2, EmojiNamesState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _EmojiNamesStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

