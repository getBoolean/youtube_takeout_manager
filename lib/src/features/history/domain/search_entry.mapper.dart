// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'search_entry.dart';

class SearchEntryMapper extends ClassMapperBase<SearchEntry> {
  SearchEntryMapper._();

  static SearchEntryMapper? _instance;
  static SearchEntryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SearchEntryMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'SearchEntry';

  static DateTime _$time(SearchEntry v) => v.time;
  static const Field<SearchEntry, DateTime> _f$time = Field('time', _$time);
  static bool _$music(SearchEntry v) => v.music;
  static const Field<SearchEntry, bool> _f$music = Field(
    'music',
    _$music,
    opt: true,
    def: false,
  );
  static String _$query(SearchEntry v) => v.query;
  static const Field<SearchEntry, String> _f$query = Field('query', _$query);
  static DateTime? _$removedAt(SearchEntry v) => v.removedAt;
  static const Field<SearchEntry, DateTime> _f$removedAt = Field(
    'removedAt',
    _$removedAt,
    opt: true,
  );
  static String _$searchText(SearchEntry v) => v.searchText;
  static const Field<SearchEntry, String> _f$searchText = Field(
    'searchText',
    _$searchText,
    mode: FieldMode.member,
  );

  @override
  final MappableFields<SearchEntry> fields = const {
    #time: _f$time,
    #music: _f$music,
    #query: _f$query,
    #removedAt: _f$removedAt,
    #searchText: _f$searchText,
  };

  static SearchEntry _instantiate(DecodingData data) {
    return SearchEntry(
      time: data.dec(_f$time),
      music: data.dec(_f$music),
      query: data.dec(_f$query),
      removedAt: data.dec(_f$removedAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SearchEntry fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SearchEntry>(map);
  }

  static SearchEntry fromJson(String json) {
    return ensureInitialized().decodeJson<SearchEntry>(json);
  }
}

mixin SearchEntryMappable {
  String toJson() {
    return SearchEntryMapper.ensureInitialized().encodeJson<SearchEntry>(
      this as SearchEntry,
    );
  }

  Map<String, dynamic> toMap() {
    return SearchEntryMapper.ensureInitialized().encodeMap<SearchEntry>(
      this as SearchEntry,
    );
  }

  SearchEntryCopyWith<SearchEntry, SearchEntry, SearchEntry> get copyWith =>
      _SearchEntryCopyWithImpl<SearchEntry, SearchEntry>(
        this as SearchEntry,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SearchEntryMapper.ensureInitialized().stringifyValue(
      this as SearchEntry,
    );
  }

  @override
  bool operator ==(Object other) {
    return SearchEntryMapper.ensureInitialized().equalsValue(
      this as SearchEntry,
      other,
    );
  }

  @override
  int get hashCode {
    return SearchEntryMapper.ensureInitialized().hashValue(this as SearchEntry);
  }
}

extension SearchEntryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SearchEntry, $Out> {
  SearchEntryCopyWith<$R, SearchEntry, $Out> get $asSearchEntry =>
      $base.as((v, t, t2) => _SearchEntryCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SearchEntryCopyWith<$R, $In extends SearchEntry, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({DateTime? time, bool? music, String? query, DateTime? removedAt});
  SearchEntryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SearchEntryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SearchEntry, $Out>
    implements SearchEntryCopyWith<$R, SearchEntry, $Out> {
  _SearchEntryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SearchEntry> $mapper =
      SearchEntryMapper.ensureInitialized();
  @override
  $R call({
    DateTime? time,
    bool? music,
    String? query,
    Object? removedAt = $none,
  }) => $apply(
    FieldCopyWithData({
      if (time != null) #time: time,
      if (music != null) #music: music,
      if (query != null) #query: query,
      if (removedAt != $none) #removedAt: removedAt,
    }),
  );
  @override
  SearchEntry $make(CopyWithData data) => SearchEntry(
    time: data.get(#time, or: $value.time),
    music: data.get(#music, or: $value.music),
    query: data.get(#query, or: $value.query),
    removedAt: data.get(#removedAt, or: $value.removedAt),
  );

  @override
  SearchEntryCopyWith<$R2, SearchEntry, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SearchEntryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

