// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'sub_category.dart';

class NameOriginMapper extends EnumMapper<NameOrigin> {
  NameOriginMapper._();

  static NameOriginMapper? _instance;
  static NameOriginMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = NameOriginMapper._());
    }
    return _instance!;
  }

  static NameOrigin fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  NameOrigin decode(dynamic value) {
    switch (value) {
      case r'ai':
        return NameOrigin.ai;
      case r'user':
        return NameOrigin.user;
      default:
        return NameOrigin.values[0];
    }
  }

  @override
  dynamic encode(NameOrigin self) {
    switch (self) {
      case NameOrigin.ai:
        return r'ai';
      case NameOrigin.user:
        return r'user';
    }
  }
}

extension NameOriginMapperExtension on NameOrigin {
  String toValue() {
    NameOriginMapper.ensureInitialized();
    return MapperContainer.globals.toValue<NameOrigin>(this) as String;
  }
}

class SubCategoryMapper extends ClassMapperBase<SubCategory> {
  SubCategoryMapper._();

  static SubCategoryMapper? _instance;
  static SubCategoryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SubCategoryMapper._());
      NameOriginMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SubCategory';

  static String _$name(SubCategory v) => v.name;
  static const Field<SubCategory, String> _f$name = Field('name', _$name);
  static NameOrigin _$origin(SubCategory v) => v.origin;
  static const Field<SubCategory, NameOrigin> _f$origin = Field(
    'origin',
    _$origin,
    opt: true,
    def: NameOrigin.ai,
  );
  static String? _$emoji(SubCategory v) => v.emoji;
  static const Field<SubCategory, String> _f$emoji = Field(
    'emoji',
    _$emoji,
    opt: true,
  );

  @override
  final MappableFields<SubCategory> fields = const {
    #name: _f$name,
    #origin: _f$origin,
    #emoji: _f$emoji,
  };

  static SubCategory _instantiate(DecodingData data) {
    return SubCategory(
      name: data.dec(_f$name),
      origin: data.dec(_f$origin),
      emoji: data.dec(_f$emoji),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SubCategory fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SubCategory>(map);
  }

  static SubCategory fromJson(String json) {
    return ensureInitialized().decodeJson<SubCategory>(json);
  }
}

mixin SubCategoryMappable {
  String toJson() {
    return SubCategoryMapper.ensureInitialized().encodeJson<SubCategory>(
      this as SubCategory,
    );
  }

  Map<String, dynamic> toMap() {
    return SubCategoryMapper.ensureInitialized().encodeMap<SubCategory>(
      this as SubCategory,
    );
  }

  SubCategoryCopyWith<SubCategory, SubCategory, SubCategory> get copyWith =>
      _SubCategoryCopyWithImpl<SubCategory, SubCategory>(
        this as SubCategory,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SubCategoryMapper.ensureInitialized().stringifyValue(
      this as SubCategory,
    );
  }

  @override
  bool operator ==(Object other) {
    return SubCategoryMapper.ensureInitialized().equalsValue(
      this as SubCategory,
      other,
    );
  }

  @override
  int get hashCode {
    return SubCategoryMapper.ensureInitialized().hashValue(this as SubCategory);
  }
}

extension SubCategoryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SubCategory, $Out> {
  SubCategoryCopyWith<$R, SubCategory, $Out> get $asSubCategory =>
      $base.as((v, t, t2) => _SubCategoryCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SubCategoryCopyWith<$R, $In extends SubCategory, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? name, NameOrigin? origin, String? emoji});
  SubCategoryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SubCategoryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SubCategory, $Out>
    implements SubCategoryCopyWith<$R, SubCategory, $Out> {
  _SubCategoryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SubCategory> $mapper =
      SubCategoryMapper.ensureInitialized();
  @override
  $R call({String? name, NameOrigin? origin, Object? emoji = $none}) => $apply(
    FieldCopyWithData({
      if (name != null) #name: name,
      if (origin != null) #origin: origin,
      if (emoji != $none) #emoji: emoji,
    }),
  );
  @override
  SubCategory $make(CopyWithData data) => SubCategory(
    name: data.get(#name, or: $value.name),
    origin: data.get(#origin, or: $value.origin),
    emoji: data.get(#emoji, or: $value.emoji),
  );

  @override
  SubCategoryCopyWith<$R2, SubCategory, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SubCategoryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

