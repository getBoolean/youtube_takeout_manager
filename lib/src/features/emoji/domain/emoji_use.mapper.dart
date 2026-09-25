// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'emoji_use.dart';

class EmojiUseMapper extends ClassMapperBase<EmojiUse> {
  EmojiUseMapper._();

  static EmojiUseMapper? _instance;
  static EmojiUseMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = EmojiUseMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'EmojiUse';

  static String _$id(EmojiUse v) => v.id;
  static const Field<EmojiUse, String> _f$id = Field('id', _$id);
  static int _$count(EmojiUse v) => v.count;
  static const Field<EmojiUse, int> _f$count = Field('count', _$count);
  static DateTime _$lastUsed(EmojiUse v) => v.lastUsed;
  static const Field<EmojiUse, DateTime> _f$lastUsed = Field(
    'lastUsed',
    _$lastUsed,
  );

  @override
  final MappableFields<EmojiUse> fields = const {
    #id: _f$id,
    #count: _f$count,
    #lastUsed: _f$lastUsed,
  };

  static EmojiUse _instantiate(DecodingData data) {
    return EmojiUse(
      id: data.dec(_f$id),
      count: data.dec(_f$count),
      lastUsed: data.dec(_f$lastUsed),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static EmojiUse fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<EmojiUse>(map);
  }

  static EmojiUse fromJson(String json) {
    return ensureInitialized().decodeJson<EmojiUse>(json);
  }
}

mixin EmojiUseMappable {
  String toJson() {
    return EmojiUseMapper.ensureInitialized().encodeJson<EmojiUse>(
      this as EmojiUse,
    );
  }

  Map<String, dynamic> toMap() {
    return EmojiUseMapper.ensureInitialized().encodeMap<EmojiUse>(
      this as EmojiUse,
    );
  }

  EmojiUseCopyWith<EmojiUse, EmojiUse, EmojiUse> get copyWith =>
      _EmojiUseCopyWithImpl<EmojiUse, EmojiUse>(
        this as EmojiUse,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return EmojiUseMapper.ensureInitialized().stringifyValue(this as EmojiUse);
  }

  @override
  bool operator ==(Object other) {
    return EmojiUseMapper.ensureInitialized().equalsValue(
      this as EmojiUse,
      other,
    );
  }

  @override
  int get hashCode {
    return EmojiUseMapper.ensureInitialized().hashValue(this as EmojiUse);
  }
}

extension EmojiUseValueCopy<$R, $Out> on ObjectCopyWith<$R, EmojiUse, $Out> {
  EmojiUseCopyWith<$R, EmojiUse, $Out> get $asEmojiUse =>
      $base.as((v, t, t2) => _EmojiUseCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class EmojiUseCopyWith<$R, $In extends EmojiUse, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? id, int? count, DateTime? lastUsed});
  EmojiUseCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _EmojiUseCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, EmojiUse, $Out>
    implements EmojiUseCopyWith<$R, EmojiUse, $Out> {
  _EmojiUseCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<EmojiUse> $mapper =
      EmojiUseMapper.ensureInitialized();
  @override
  $R call({String? id, int? count, DateTime? lastUsed}) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (count != null) #count: count,
      if (lastUsed != null) #lastUsed: lastUsed,
    }),
  );
  @override
  EmojiUse $make(CopyWithData data) => EmojiUse(
    id: data.get(#id, or: $value.id),
    count: data.get(#count, or: $value.count),
    lastUsed: data.get(#lastUsed, or: $value.lastUsed),
  );

  @override
  EmojiUseCopyWith<$R2, EmojiUse, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _EmojiUseCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

