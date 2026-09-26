// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'takeout_selection.dart';

class TakeoutSelectionMapper extends ClassMapperBase<TakeoutSelection> {
  TakeoutSelectionMapper._();

  static TakeoutSelectionMapper? _instance;
  static TakeoutSelectionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TakeoutSelectionMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'TakeoutSelection';

  static String _$takeoutId(TakeoutSelection v) => v.takeoutId;
  static const Field<TakeoutSelection, String> _f$takeoutId = Field(
    'takeoutId',
    _$takeoutId,
  );
  static String? _$channelId(TakeoutSelection v) => v.channelId;
  static const Field<TakeoutSelection, String> _f$channelId = Field(
    'channelId',
    _$channelId,
    opt: true,
  );

  @override
  final MappableFields<TakeoutSelection> fields = const {
    #takeoutId: _f$takeoutId,
    #channelId: _f$channelId,
  };

  static TakeoutSelection _instantiate(DecodingData data) {
    return TakeoutSelection(
      takeoutId: data.dec(_f$takeoutId),
      channelId: data.dec(_f$channelId),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static TakeoutSelection fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<TakeoutSelection>(map);
  }

  static TakeoutSelection fromJson(String json) {
    return ensureInitialized().decodeJson<TakeoutSelection>(json);
  }
}

mixin TakeoutSelectionMappable {
  String toJson() {
    return TakeoutSelectionMapper.ensureInitialized()
        .encodeJson<TakeoutSelection>(this as TakeoutSelection);
  }

  Map<String, dynamic> toMap() {
    return TakeoutSelectionMapper.ensureInitialized()
        .encodeMap<TakeoutSelection>(this as TakeoutSelection);
  }

  TakeoutSelectionCopyWith<TakeoutSelection, TakeoutSelection, TakeoutSelection>
  get copyWith =>
      _TakeoutSelectionCopyWithImpl<TakeoutSelection, TakeoutSelection>(
        this as TakeoutSelection,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return TakeoutSelectionMapper.ensureInitialized().stringifyValue(
      this as TakeoutSelection,
    );
  }

  @override
  bool operator ==(Object other) {
    return TakeoutSelectionMapper.ensureInitialized().equalsValue(
      this as TakeoutSelection,
      other,
    );
  }

  @override
  int get hashCode {
    return TakeoutSelectionMapper.ensureInitialized().hashValue(
      this as TakeoutSelection,
    );
  }
}

extension TakeoutSelectionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, TakeoutSelection, $Out> {
  TakeoutSelectionCopyWith<$R, TakeoutSelection, $Out>
  get $asTakeoutSelection =>
      $base.as((v, t, t2) => _TakeoutSelectionCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class TakeoutSelectionCopyWith<$R, $In extends TakeoutSelection, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? takeoutId, String? channelId});
  TakeoutSelectionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _TakeoutSelectionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, TakeoutSelection, $Out>
    implements TakeoutSelectionCopyWith<$R, TakeoutSelection, $Out> {
  _TakeoutSelectionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<TakeoutSelection> $mapper =
      TakeoutSelectionMapper.ensureInitialized();
  @override
  $R call({String? takeoutId, Object? channelId = $none}) => $apply(
    FieldCopyWithData({
      if (takeoutId != null) #takeoutId: takeoutId,
      if (channelId != $none) #channelId: channelId,
    }),
  );
  @override
  TakeoutSelection $make(CopyWithData data) => TakeoutSelection(
    takeoutId: data.get(#takeoutId, or: $value.takeoutId),
    channelId: data.get(#channelId, or: $value.channelId),
  );

  @override
  TakeoutSelectionCopyWith<$R2, TakeoutSelection, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _TakeoutSelectionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

