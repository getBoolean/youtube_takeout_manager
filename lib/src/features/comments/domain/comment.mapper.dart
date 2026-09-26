// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'comment.dart';

class CommentMapper extends ClassMapperBase<Comment> {
  CommentMapper._();

  static CommentMapper? _instance;
  static CommentMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CommentMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'Comment';

  static String _$commentId(Comment v) => v.commentId;
  static const Field<Comment, String> _f$commentId = Field(
    'commentId',
    _$commentId,
  );
  static String _$channelId(Comment v) => v.channelId;
  static const Field<Comment, String> _f$channelId = Field(
    'channelId',
    _$channelId,
  );
  static DateTime _$createdAt(Comment v) => v.createdAt;
  static const Field<Comment, DateTime> _f$createdAt = Field(
    'createdAt',
    _$createdAt,
  );
  static double _$price(Comment v) => v.price;
  static const Field<Comment, double> _f$price = Field('price', _$price);
  static String? _$parentCommentId(Comment v) => v.parentCommentId;
  static const Field<Comment, String> _f$parentCommentId = Field(
    'parentCommentId',
    _$parentCommentId,
    opt: true,
  );
  static String? _$postId(Comment v) => v.postId;
  static const Field<Comment, String> _f$postId = Field(
    'postId',
    _$postId,
    opt: true,
  );
  static String? _$videoId(Comment v) => v.videoId;
  static const Field<Comment, String> _f$videoId = Field(
    'videoId',
    _$videoId,
    opt: true,
  );
  static String _$rawCommentText(Comment v) => v.rawCommentText;
  static const Field<Comment, String> _f$rawCommentText = Field(
    'rawCommentText',
    _$rawCommentText,
  );
  static String _$displayText(Comment v) => v.displayText;
  static const Field<Comment, String> _f$displayText = Field(
    'displayText',
    _$displayText,
  );
  static String? _$topLevelCommentId(Comment v) => v.topLevelCommentId;
  static const Field<Comment, String> _f$topLevelCommentId = Field(
    'topLevelCommentId',
    _$topLevelCommentId,
    opt: true,
  );

  @override
  final MappableFields<Comment> fields = const {
    #commentId: _f$commentId,
    #channelId: _f$channelId,
    #createdAt: _f$createdAt,
    #price: _f$price,
    #parentCommentId: _f$parentCommentId,
    #postId: _f$postId,
    #videoId: _f$videoId,
    #rawCommentText: _f$rawCommentText,
    #displayText: _f$displayText,
    #topLevelCommentId: _f$topLevelCommentId,
  };

  static Comment _instantiate(DecodingData data) {
    return Comment(
      commentId: data.dec(_f$commentId),
      channelId: data.dec(_f$channelId),
      createdAt: data.dec(_f$createdAt),
      price: data.dec(_f$price),
      parentCommentId: data.dec(_f$parentCommentId),
      postId: data.dec(_f$postId),
      videoId: data.dec(_f$videoId),
      rawCommentText: data.dec(_f$rawCommentText),
      displayText: data.dec(_f$displayText),
      topLevelCommentId: data.dec(_f$topLevelCommentId),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Comment fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Comment>(map);
  }

  static Comment fromJson(String json) {
    return ensureInitialized().decodeJson<Comment>(json);
  }
}

mixin CommentMappable {
  String toJson() {
    return CommentMapper.ensureInitialized().encodeJson<Comment>(
      this as Comment,
    );
  }

  Map<String, dynamic> toMap() {
    return CommentMapper.ensureInitialized().encodeMap<Comment>(
      this as Comment,
    );
  }

  CommentCopyWith<Comment, Comment, Comment> get copyWith =>
      _CommentCopyWithImpl<Comment, Comment>(
        this as Comment,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return CommentMapper.ensureInitialized().stringifyValue(this as Comment);
  }

  @override
  bool operator ==(Object other) {
    return CommentMapper.ensureInitialized().equalsValue(
      this as Comment,
      other,
    );
  }

  @override
  int get hashCode {
    return CommentMapper.ensureInitialized().hashValue(this as Comment);
  }
}

extension CommentValueCopy<$R, $Out> on ObjectCopyWith<$R, Comment, $Out> {
  CommentCopyWith<$R, Comment, $Out> get $asComment =>
      $base.as((v, t, t2) => _CommentCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class CommentCopyWith<$R, $In extends Comment, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? commentId,
    String? channelId,
    DateTime? createdAt,
    double? price,
    String? parentCommentId,
    String? postId,
    String? videoId,
    String? rawCommentText,
    String? displayText,
    String? topLevelCommentId,
  });
  CommentCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _CommentCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Comment, $Out>
    implements CommentCopyWith<$R, Comment, $Out> {
  _CommentCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Comment> $mapper =
      CommentMapper.ensureInitialized();
  @override
  $R call({
    String? commentId,
    String? channelId,
    DateTime? createdAt,
    double? price,
    Object? parentCommentId = $none,
    Object? postId = $none,
    Object? videoId = $none,
    String? rawCommentText,
    String? displayText,
    Object? topLevelCommentId = $none,
  }) => $apply(
    FieldCopyWithData({
      if (commentId != null) #commentId: commentId,
      if (channelId != null) #channelId: channelId,
      if (createdAt != null) #createdAt: createdAt,
      if (price != null) #price: price,
      if (parentCommentId != $none) #parentCommentId: parentCommentId,
      if (postId != $none) #postId: postId,
      if (videoId != $none) #videoId: videoId,
      if (rawCommentText != null) #rawCommentText: rawCommentText,
      if (displayText != null) #displayText: displayText,
      if (topLevelCommentId != $none) #topLevelCommentId: topLevelCommentId,
    }),
  );
  @override
  Comment $make(CopyWithData data) => Comment(
    commentId: data.get(#commentId, or: $value.commentId),
    channelId: data.get(#channelId, or: $value.channelId),
    createdAt: data.get(#createdAt, or: $value.createdAt),
    price: data.get(#price, or: $value.price),
    parentCommentId: data.get(#parentCommentId, or: $value.parentCommentId),
    postId: data.get(#postId, or: $value.postId),
    videoId: data.get(#videoId, or: $value.videoId),
    rawCommentText: data.get(#rawCommentText, or: $value.rawCommentText),
    displayText: data.get(#displayText, or: $value.displayText),
    topLevelCommentId: data.get(
      #topLevelCommentId,
      or: $value.topLevelCommentId,
    ),
  );

  @override
  CommentCopyWith<$R2, Comment, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _CommentCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

