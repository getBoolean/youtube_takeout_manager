// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'model_capabilities.dart';

class ModelCapabilitiesMapper extends ClassMapperBase<ModelCapabilities> {
  ModelCapabilitiesMapper._();

  static ModelCapabilitiesMapper? _instance;
  static ModelCapabilitiesMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModelCapabilitiesMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ModelCapabilities';

  static String _$id(ModelCapabilities v) => v.id;
  static const Field<ModelCapabilities, String> _f$id = Field('id', _$id);
  static bool _$structuredOutputs(ModelCapabilities v) => v.structuredOutputs;
  static const Field<ModelCapabilities, bool> _f$structuredOutputs = Field(
    'structuredOutputs',
    _$structuredOutputs,
  );
  static bool _$lowEffort(ModelCapabilities v) => v.lowEffort;
  static const Field<ModelCapabilities, bool> _f$lowEffort = Field(
    'lowEffort',
    _$lowEffort,
  );
  static int? _$maxTokens(ModelCapabilities v) => v.maxTokens;
  static const Field<ModelCapabilities, int> _f$maxTokens = Field(
    'maxTokens',
    _$maxTokens,
    opt: true,
  );

  @override
  final MappableFields<ModelCapabilities> fields = const {
    #id: _f$id,
    #structuredOutputs: _f$structuredOutputs,
    #lowEffort: _f$lowEffort,
    #maxTokens: _f$maxTokens,
  };

  static ModelCapabilities _instantiate(DecodingData data) {
    return ModelCapabilities(
      id: data.dec(_f$id),
      structuredOutputs: data.dec(_f$structuredOutputs),
      lowEffort: data.dec(_f$lowEffort),
      maxTokens: data.dec(_f$maxTokens),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModelCapabilities fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModelCapabilities>(map);
  }

  static ModelCapabilities fromJson(String json) {
    return ensureInitialized().decodeJson<ModelCapabilities>(json);
  }
}

mixin ModelCapabilitiesMappable {
  String toJson() {
    return ModelCapabilitiesMapper.ensureInitialized()
        .encodeJson<ModelCapabilities>(this as ModelCapabilities);
  }

  Map<String, dynamic> toMap() {
    return ModelCapabilitiesMapper.ensureInitialized()
        .encodeMap<ModelCapabilities>(this as ModelCapabilities);
  }

  ModelCapabilitiesCopyWith<
    ModelCapabilities,
    ModelCapabilities,
    ModelCapabilities
  >
  get copyWith =>
      _ModelCapabilitiesCopyWithImpl<ModelCapabilities, ModelCapabilities>(
        this as ModelCapabilities,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ModelCapabilitiesMapper.ensureInitialized().stringifyValue(
      this as ModelCapabilities,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModelCapabilitiesMapper.ensureInitialized().equalsValue(
      this as ModelCapabilities,
      other,
    );
  }

  @override
  int get hashCode {
    return ModelCapabilitiesMapper.ensureInitialized().hashValue(
      this as ModelCapabilities,
    );
  }
}

extension ModelCapabilitiesValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModelCapabilities, $Out> {
  ModelCapabilitiesCopyWith<$R, ModelCapabilities, $Out>
  get $asModelCapabilities => $base.as(
    (v, t, t2) => _ModelCapabilitiesCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ModelCapabilitiesCopyWith<
  $R,
  $In extends ModelCapabilities,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    bool? structuredOutputs,
    bool? lowEffort,
    int? maxTokens,
  });
  ModelCapabilitiesCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ModelCapabilitiesCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModelCapabilities, $Out>
    implements ModelCapabilitiesCopyWith<$R, ModelCapabilities, $Out> {
  _ModelCapabilitiesCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModelCapabilities> $mapper =
      ModelCapabilitiesMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    bool? structuredOutputs,
    bool? lowEffort,
    Object? maxTokens = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (structuredOutputs != null) #structuredOutputs: structuredOutputs,
      if (lowEffort != null) #lowEffort: lowEffort,
      if (maxTokens != $none) #maxTokens: maxTokens,
    }),
  );
  @override
  ModelCapabilities $make(CopyWithData data) => ModelCapabilities(
    id: data.get(#id, or: $value.id),
    structuredOutputs: data.get(
      #structuredOutputs,
      or: $value.structuredOutputs,
    ),
    lowEffort: data.get(#lowEffort, or: $value.lowEffort),
    maxTokens: data.get(#maxTokens, or: $value.maxTokens),
  );

  @override
  ModelCapabilitiesCopyWith<$R2, ModelCapabilities, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ModelCapabilitiesCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

