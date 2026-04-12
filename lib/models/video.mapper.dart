// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'video.dart';

class VideoMapper extends ClassMapperBase<Video> {
  VideoMapper._();

  static VideoMapper? _instance;
  static VideoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = VideoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'Video';

  static String _$videoId(Video v) => v.videoId;
  static const Field<Video, String> _f$videoId = Field('videoId', _$videoId);
  static String _$channelId(Video v) => v.channelId;
  static const Field<Video, String> _f$channelId = Field(
    'channelId',
    _$channelId,
  );
  static String? _$channelTitle(Video v) => v.channelTitle;
  static const Field<Video, String> _f$channelTitle = Field(
    'channelTitle',
    _$channelTitle,
    opt: true,
  );
  static String? _$title(Video v) => v.title;
  static const Field<Video, String> _f$title = Field(
    'title',
    _$title,
    opt: true,
  );
  static String? _$description(Video v) => v.description;
  static const Field<Video, String> _f$description = Field(
    'description',
    _$description,
    opt: true,
  );
  static String? _$thumbnailUrl(Video v) => v.thumbnailUrl;
  static const Field<Video, String> _f$thumbnailUrl = Field(
    'thumbnailUrl',
    _$thumbnailUrl,
    opt: true,
  );
  static DateTime? _$publishedAt(Video v) => v.publishedAt;
  static const Field<Video, DateTime> _f$publishedAt = Field(
    'publishedAt',
    _$publishedAt,
    opt: true,
  );

  @override
  final MappableFields<Video> fields = const {
    #videoId: _f$videoId,
    #channelId: _f$channelId,
    #channelTitle: _f$channelTitle,
    #title: _f$title,
    #description: _f$description,
    #thumbnailUrl: _f$thumbnailUrl,
    #publishedAt: _f$publishedAt,
  };

  static Video _instantiate(DecodingData data) {
    return Video(
      videoId: data.dec(_f$videoId),
      channelId: data.dec(_f$channelId),
      channelTitle: data.dec(_f$channelTitle),
      title: data.dec(_f$title),
      description: data.dec(_f$description),
      thumbnailUrl: data.dec(_f$thumbnailUrl),
      publishedAt: data.dec(_f$publishedAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Video fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Video>(map);
  }

  static Video fromJson(String json) {
    return ensureInitialized().decodeJson<Video>(json);
  }
}

mixin VideoMappable {
  String toJson() {
    return VideoMapper.ensureInitialized().encodeJson<Video>(this as Video);
  }

  Map<String, dynamic> toMap() {
    return VideoMapper.ensureInitialized().encodeMap<Video>(this as Video);
  }

  VideoCopyWith<Video, Video, Video> get copyWith =>
      _VideoCopyWithImpl<Video, Video>(this as Video, $identity, $identity);
  @override
  String toString() {
    return VideoMapper.ensureInitialized().stringifyValue(this as Video);
  }

  @override
  bool operator ==(Object other) {
    return VideoMapper.ensureInitialized().equalsValue(this as Video, other);
  }

  @override
  int get hashCode {
    return VideoMapper.ensureInitialized().hashValue(this as Video);
  }
}

extension VideoValueCopy<$R, $Out> on ObjectCopyWith<$R, Video, $Out> {
  VideoCopyWith<$R, Video, $Out> get $asVideo =>
      $base.as((v, t, t2) => _VideoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class VideoCopyWith<$R, $In extends Video, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? videoId,
    String? channelId,
    String? channelTitle,
    String? title,
    String? description,
    String? thumbnailUrl,
    DateTime? publishedAt,
  });
  VideoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _VideoCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Video, $Out>
    implements VideoCopyWith<$R, Video, $Out> {
  _VideoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Video> $mapper = VideoMapper.ensureInitialized();
  @override
  $R call({
    String? videoId,
    String? channelId,
    Object? channelTitle = $none,
    Object? title = $none,
    Object? description = $none,
    Object? thumbnailUrl = $none,
    Object? publishedAt = $none,
  }) => $apply(
    FieldCopyWithData({
      if (videoId != null) #videoId: videoId,
      if (channelId != null) #channelId: channelId,
      if (channelTitle != $none) #channelTitle: channelTitle,
      if (title != $none) #title: title,
      if (description != $none) #description: description,
      if (thumbnailUrl != $none) #thumbnailUrl: thumbnailUrl,
      if (publishedAt != $none) #publishedAt: publishedAt,
    }),
  );
  @override
  Video $make(CopyWithData data) => Video(
    videoId: data.get(#videoId, or: $value.videoId),
    channelId: data.get(#channelId, or: $value.channelId),
    channelTitle: data.get(#channelTitle, or: $value.channelTitle),
    title: data.get(#title, or: $value.title),
    description: data.get(#description, or: $value.description),
    thumbnailUrl: data.get(#thumbnailUrl, or: $value.thumbnailUrl),
    publishedAt: data.get(#publishedAt, or: $value.publishedAt),
  );

  @override
  VideoCopyWith<$R2, Video, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _VideoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

