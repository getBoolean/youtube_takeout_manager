// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'tag_name.dart';

class TagNameMapper extends ClassMapperBase<TagName> {
  TagNameMapper._();

  static TagNameMapper? _instance;
  static TagNameMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TagNameMapper._());
      NameOriginMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'TagName';

  static String _$name(TagName v) => v.name;
  static const Field<TagName, String> _f$name = Field('name', _$name);
  static NameOrigin _$origin(TagName v) => v.origin;
  static const Field<TagName, NameOrigin> _f$origin = Field(
    'origin',
    _$origin,
    opt: true,
    def: NameOrigin.ai,
  );

  @override
  final MappableFields<TagName> fields = const {
    #name: _f$name,
    #origin: _f$origin,
  };

  static TagName _instantiate(DecodingData data) {
    return TagName(name: data.dec(_f$name), origin: data.dec(_f$origin));
  }

  @override
  final Function instantiate = _instantiate;

  static TagName fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<TagName>(map);
  }

  static TagName fromJson(String json) {
    return ensureInitialized().decodeJson<TagName>(json);
  }
}

mixin TagNameMappable {
  String toJson() {
    return TagNameMapper.ensureInitialized().encodeJson<TagName>(
      this as TagName,
    );
  }

  Map<String, dynamic> toMap() {
    return TagNameMapper.ensureInitialized().encodeMap<TagName>(
      this as TagName,
    );
  }

  TagNameCopyWith<TagName, TagName, TagName> get copyWith =>
      _TagNameCopyWithImpl<TagName, TagName>(
        this as TagName,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return TagNameMapper.ensureInitialized().stringifyValue(this as TagName);
  }

  @override
  bool operator ==(Object other) {
    return TagNameMapper.ensureInitialized().equalsValue(
      this as TagName,
      other,
    );
  }

  @override
  int get hashCode {
    return TagNameMapper.ensureInitialized().hashValue(this as TagName);
  }
}

extension TagNameValueCopy<$R, $Out> on ObjectCopyWith<$R, TagName, $Out> {
  TagNameCopyWith<$R, TagName, $Out> get $asTagName =>
      $base.as((v, t, t2) => _TagNameCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class TagNameCopyWith<$R, $In extends TagName, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? name, NameOrigin? origin});
  TagNameCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _TagNameCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, TagName, $Out>
    implements TagNameCopyWith<$R, TagName, $Out> {
  _TagNameCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<TagName> $mapper =
      TagNameMapper.ensureInitialized();
  @override
  $R call({String? name, NameOrigin? origin}) => $apply(
    FieldCopyWithData({
      if (name != null) #name: name,
      if (origin != null) #origin: origin,
    }),
  );
  @override
  TagName $make(CopyWithData data) => TagName(
    name: data.get(#name, or: $value.name),
    origin: data.get(#origin, or: $value.origin),
  );

  @override
  TagNameCopyWith<$R2, TagName, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _TagNameCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

