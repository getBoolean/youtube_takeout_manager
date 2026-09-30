// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'category_path.dart';

class CategoryPathMapper extends ClassMapperBase<CategoryPath> {
  CategoryPathMapper._();

  static CategoryPathMapper? _instance;
  static CategoryPathMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CategoryPathMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'CategoryPath';

  static String _$parent(CategoryPath v) => v.parent;
  static const Field<CategoryPath, String> _f$parent = Field(
    'parent',
    _$parent,
  );
  static String? _$child(CategoryPath v) => v.child;
  static const Field<CategoryPath, String> _f$child = Field(
    'child',
    _$child,
    opt: true,
  );

  @override
  final MappableFields<CategoryPath> fields = const {
    #parent: _f$parent,
    #child: _f$child,
  };

  static CategoryPath _instantiate(DecodingData data) {
    return CategoryPath(data.dec(_f$parent), data.dec(_f$child));
  }

  @override
  final Function instantiate = _instantiate;

  static CategoryPath fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CategoryPath>(map);
  }

  static CategoryPath fromJson(String json) {
    return ensureInitialized().decodeJson<CategoryPath>(json);
  }
}

mixin CategoryPathMappable {
  String toJson() {
    return CategoryPathMapper.ensureInitialized().encodeJson<CategoryPath>(
      this as CategoryPath,
    );
  }

  Map<String, dynamic> toMap() {
    return CategoryPathMapper.ensureInitialized().encodeMap<CategoryPath>(
      this as CategoryPath,
    );
  }

  CategoryPathCopyWith<CategoryPath, CategoryPath, CategoryPath> get copyWith =>
      _CategoryPathCopyWithImpl<CategoryPath, CategoryPath>(
        this as CategoryPath,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return CategoryPathMapper.ensureInitialized().stringifyValue(
      this as CategoryPath,
    );
  }

  @override
  bool operator ==(Object other) {
    return CategoryPathMapper.ensureInitialized().equalsValue(
      this as CategoryPath,
      other,
    );
  }

  @override
  int get hashCode {
    return CategoryPathMapper.ensureInitialized().hashValue(
      this as CategoryPath,
    );
  }
}

extension CategoryPathValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CategoryPath, $Out> {
  CategoryPathCopyWith<$R, CategoryPath, $Out> get $asCategoryPath =>
      $base.as((v, t, t2) => _CategoryPathCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class CategoryPathCopyWith<$R, $In extends CategoryPath, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? parent, String? child});
  CategoryPathCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _CategoryPathCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CategoryPath, $Out>
    implements CategoryPathCopyWith<$R, CategoryPath, $Out> {
  _CategoryPathCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CategoryPath> $mapper =
      CategoryPathMapper.ensureInitialized();
  @override
  $R call({String? parent, Object? child = $none}) => $apply(
    FieldCopyWithData({
      if (parent != null) #parent: parent,
      if (child != $none) #child: child,
    }),
  );
  @override
  CategoryPath $make(CopyWithData data) => CategoryPath(
    data.get(#parent, or: $value.parent),
    data.get(#child, or: $value.child),
  );

  @override
  CategoryPathCopyWith<$R2, CategoryPath, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _CategoryPathCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

