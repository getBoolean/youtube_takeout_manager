// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'search_options_state.dart';

class SearchOptionsStateMapper extends ClassMapperBase<SearchOptionsState> {
  SearchOptionsStateMapper._();

  static SearchOptionsStateMapper? _instance;
  static SearchOptionsStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SearchOptionsStateMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'SearchOptionsState';

  static bool _$expandMatchedVideos(SearchOptionsState v) =>
      v.expandMatchedVideos;
  static const Field<SearchOptionsState, bool> _f$expandMatchedVideos = Field(
    'expandMatchedVideos',
    _$expandMatchedVideos,
    opt: true,
    def: false,
  );
  static bool _$matchGroupTitles(SearchOptionsState v) => v.matchGroupTitles;
  static const Field<SearchOptionsState, bool> _f$matchGroupTitles = Field(
    'matchGroupTitles',
    _$matchGroupTitles,
    opt: true,
    def: true,
  );

  @override
  final MappableFields<SearchOptionsState> fields = const {
    #expandMatchedVideos: _f$expandMatchedVideos,
    #matchGroupTitles: _f$matchGroupTitles,
  };

  static SearchOptionsState _instantiate(DecodingData data) {
    return SearchOptionsState(
      expandMatchedVideos: data.dec(_f$expandMatchedVideos),
      matchGroupTitles: data.dec(_f$matchGroupTitles),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SearchOptionsState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SearchOptionsState>(map);
  }

  static SearchOptionsState fromJson(String json) {
    return ensureInitialized().decodeJson<SearchOptionsState>(json);
  }
}

mixin SearchOptionsStateMappable {
  String toJson() {
    return SearchOptionsStateMapper.ensureInitialized()
        .encodeJson<SearchOptionsState>(this as SearchOptionsState);
  }

  Map<String, dynamic> toMap() {
    return SearchOptionsStateMapper.ensureInitialized()
        .encodeMap<SearchOptionsState>(this as SearchOptionsState);
  }

  SearchOptionsStateCopyWith<
    SearchOptionsState,
    SearchOptionsState,
    SearchOptionsState
  >
  get copyWith =>
      _SearchOptionsStateCopyWithImpl<SearchOptionsState, SearchOptionsState>(
        this as SearchOptionsState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SearchOptionsStateMapper.ensureInitialized().stringifyValue(
      this as SearchOptionsState,
    );
  }

  @override
  bool operator ==(Object other) {
    return SearchOptionsStateMapper.ensureInitialized().equalsValue(
      this as SearchOptionsState,
      other,
    );
  }

  @override
  int get hashCode {
    return SearchOptionsStateMapper.ensureInitialized().hashValue(
      this as SearchOptionsState,
    );
  }
}

extension SearchOptionsStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SearchOptionsState, $Out> {
  SearchOptionsStateCopyWith<$R, SearchOptionsState, $Out>
  get $asSearchOptionsState => $base.as(
    (v, t, t2) => _SearchOptionsStateCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class SearchOptionsStateCopyWith<
  $R,
  $In extends SearchOptionsState,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({bool? expandMatchedVideos, bool? matchGroupTitles});
  SearchOptionsStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _SearchOptionsStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SearchOptionsState, $Out>
    implements SearchOptionsStateCopyWith<$R, SearchOptionsState, $Out> {
  _SearchOptionsStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SearchOptionsState> $mapper =
      SearchOptionsStateMapper.ensureInitialized();
  @override
  $R call({bool? expandMatchedVideos, bool? matchGroupTitles}) => $apply(
    FieldCopyWithData({
      if (expandMatchedVideos != null)
        #expandMatchedVideos: expandMatchedVideos,
      if (matchGroupTitles != null) #matchGroupTitles: matchGroupTitles,
    }),
  );
  @override
  SearchOptionsState $make(CopyWithData data) => SearchOptionsState(
    expandMatchedVideos: data.get(
      #expandMatchedVideos,
      or: $value.expandMatchedVideos,
    ),
    matchGroupTitles: data.get(#matchGroupTitles, or: $value.matchGroupTitles),
  );

  @override
  SearchOptionsStateCopyWith<$R2, SearchOptionsState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SearchOptionsStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

