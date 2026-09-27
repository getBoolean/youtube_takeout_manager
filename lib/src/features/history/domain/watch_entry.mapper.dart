// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'watch_entry.dart';

class WatchKindMapper extends EnumMapper<WatchKind> {
  WatchKindMapper._();

  static WatchKindMapper? _instance;
  static WatchKindMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = WatchKindMapper._());
    }
    return _instance!;
  }

  static WatchKind fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  WatchKind decode(dynamic value) {
    switch (value) {
      case r'video':
        return WatchKind.video;
      case r'post':
        return WatchKind.post;
      case r'playable':
        return WatchKind.playable;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(WatchKind self) {
    switch (self) {
      case WatchKind.video:
        return r'video';
      case WatchKind.post:
        return r'post';
      case WatchKind.playable:
        return r'playable';
    }
  }
}

extension WatchKindMapperExtension on WatchKind {
  String toValue() {
    WatchKindMapper.ensureInitialized();
    return MapperContainer.globals.toValue<WatchKind>(this) as String;
  }
}

class WatchEntryMapper extends ClassMapperBase<WatchEntry> {
  WatchEntryMapper._();

  static WatchEntryMapper? _instance;
  static WatchEntryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = WatchEntryMapper._());
      WatchKindMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'WatchEntry';

  static DateTime _$time(WatchEntry v) => v.time;
  static const Field<WatchEntry, DateTime> _f$time = Field('time', _$time);
  static WatchKind _$kind(WatchEntry v) => v.kind;
  static const Field<WatchEntry, WatchKind> _f$kind = Field('kind', _$kind);
  static bool _$music(WatchEntry v) => v.music;
  static const Field<WatchEntry, bool> _f$music = Field(
    'music',
    _$music,
    opt: true,
    def: false,
  );
  static String? _$title(WatchEntry v) => v.title;
  static const Field<WatchEntry, String> _f$title = Field(
    'title',
    _$title,
    opt: true,
  );
  static String _$url(WatchEntry v) => v.url;
  static const Field<WatchEntry, String> _f$url = Field('url', _$url);
  static String? _$channelTitle(WatchEntry v) => v.channelTitle;
  static const Field<WatchEntry, String> _f$channelTitle = Field(
    'channelTitle',
    _$channelTitle,
    opt: true,
  );
  static String? _$channelUrl(WatchEntry v) => v.channelUrl;
  static const Field<WatchEntry, String> _f$channelUrl = Field(
    'channelUrl',
    _$channelUrl,
    opt: true,
  );
  static DateTime? _$removedAt(WatchEntry v) => v.removedAt;
  static const Field<WatchEntry, DateTime> _f$removedAt = Field(
    'removedAt',
    _$removedAt,
    opt: true,
  );
  static String _$searchText(WatchEntry v) => v.searchText;
  static const Field<WatchEntry, String> _f$searchText = Field(
    'searchText',
    _$searchText,
    mode: FieldMode.member,
  );

  @override
  final MappableFields<WatchEntry> fields = const {
    #time: _f$time,
    #kind: _f$kind,
    #music: _f$music,
    #title: _f$title,
    #url: _f$url,
    #channelTitle: _f$channelTitle,
    #channelUrl: _f$channelUrl,
    #removedAt: _f$removedAt,
    #searchText: _f$searchText,
  };

  static WatchEntry _instantiate(DecodingData data) {
    return WatchEntry(
      time: data.dec(_f$time),
      kind: data.dec(_f$kind),
      music: data.dec(_f$music),
      title: data.dec(_f$title),
      url: data.dec(_f$url),
      channelTitle: data.dec(_f$channelTitle),
      channelUrl: data.dec(_f$channelUrl),
      removedAt: data.dec(_f$removedAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static WatchEntry fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<WatchEntry>(map);
  }

  static WatchEntry fromJson(String json) {
    return ensureInitialized().decodeJson<WatchEntry>(json);
  }
}

mixin WatchEntryMappable {
  String toJson() {
    return WatchEntryMapper.ensureInitialized().encodeJson<WatchEntry>(
      this as WatchEntry,
    );
  }

  Map<String, dynamic> toMap() {
    return WatchEntryMapper.ensureInitialized().encodeMap<WatchEntry>(
      this as WatchEntry,
    );
  }

  WatchEntryCopyWith<WatchEntry, WatchEntry, WatchEntry> get copyWith =>
      _WatchEntryCopyWithImpl<WatchEntry, WatchEntry>(
        this as WatchEntry,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return WatchEntryMapper.ensureInitialized().stringifyValue(
      this as WatchEntry,
    );
  }

  @override
  bool operator ==(Object other) {
    return WatchEntryMapper.ensureInitialized().equalsValue(
      this as WatchEntry,
      other,
    );
  }

  @override
  int get hashCode {
    return WatchEntryMapper.ensureInitialized().hashValue(this as WatchEntry);
  }
}

extension WatchEntryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, WatchEntry, $Out> {
  WatchEntryCopyWith<$R, WatchEntry, $Out> get $asWatchEntry =>
      $base.as((v, t, t2) => _WatchEntryCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class WatchEntryCopyWith<$R, $In extends WatchEntry, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    DateTime? time,
    WatchKind? kind,
    bool? music,
    String? title,
    String? url,
    String? channelTitle,
    String? channelUrl,
    DateTime? removedAt,
  });
  WatchEntryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _WatchEntryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, WatchEntry, $Out>
    implements WatchEntryCopyWith<$R, WatchEntry, $Out> {
  _WatchEntryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<WatchEntry> $mapper =
      WatchEntryMapper.ensureInitialized();
  @override
  $R call({
    DateTime? time,
    WatchKind? kind,
    bool? music,
    Object? title = $none,
    String? url,
    Object? channelTitle = $none,
    Object? channelUrl = $none,
    Object? removedAt = $none,
  }) => $apply(
    FieldCopyWithData({
      if (time != null) #time: time,
      if (kind != null) #kind: kind,
      if (music != null) #music: music,
      if (title != $none) #title: title,
      if (url != null) #url: url,
      if (channelTitle != $none) #channelTitle: channelTitle,
      if (channelUrl != $none) #channelUrl: channelUrl,
      if (removedAt != $none) #removedAt: removedAt,
    }),
  );
  @override
  WatchEntry $make(CopyWithData data) => WatchEntry(
    time: data.get(#time, or: $value.time),
    kind: data.get(#kind, or: $value.kind),
    music: data.get(#music, or: $value.music),
    title: data.get(#title, or: $value.title),
    url: data.get(#url, or: $value.url),
    channelTitle: data.get(#channelTitle, or: $value.channelTitle),
    channelUrl: data.get(#channelUrl, or: $value.channelUrl),
    removedAt: data.get(#removedAt, or: $value.removedAt),
  );

  @override
  WatchEntryCopyWith<$R2, WatchEntry, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _WatchEntryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

