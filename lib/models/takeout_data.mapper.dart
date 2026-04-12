// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'takeout_data.dart';

class TakeoutDataMapper extends ClassMapperBase<TakeoutData> {
  TakeoutDataMapper._();

  static TakeoutDataMapper? _instance;
  static TakeoutDataMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TakeoutDataMapper._());
      CommentMapper.ensureInitialized();
      LiveChatMapper.ensureInitialized();
      SubscriptionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'TakeoutData';

  static List<Comment> _$comments(TakeoutData v) => v.comments;
  static const Field<TakeoutData, List<Comment>> _f$comments = Field(
    'comments',
    _$comments,
  );
  static List<LiveChat> _$liveChats(TakeoutData v) => v.liveChats;
  static const Field<TakeoutData, List<LiveChat>> _f$liveChats = Field(
    'liveChats',
    _$liveChats,
  );
  static Map<String, Subscription> _$subscriptionsByChannelId(TakeoutData v) =>
      v.subscriptionsByChannelId;
  static const Field<TakeoutData, Map<String, Subscription>>
  _f$subscriptionsByChannelId = Field(
    'subscriptionsByChannelId',
    _$subscriptionsByChannelId,
  );

  @override
  final MappableFields<TakeoutData> fields = const {
    #comments: _f$comments,
    #liveChats: _f$liveChats,
    #subscriptionsByChannelId: _f$subscriptionsByChannelId,
  };

  static TakeoutData _instantiate(DecodingData data) {
    return TakeoutData(
      comments: data.dec(_f$comments),
      liveChats: data.dec(_f$liveChats),
      subscriptionsByChannelId: data.dec(_f$subscriptionsByChannelId),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static TakeoutData fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<TakeoutData>(map);
  }

  static TakeoutData fromJson(String json) {
    return ensureInitialized().decodeJson<TakeoutData>(json);
  }
}

mixin TakeoutDataMappable {
  String toJson() {
    return TakeoutDataMapper.ensureInitialized().encodeJson<TakeoutData>(
      this as TakeoutData,
    );
  }

  Map<String, dynamic> toMap() {
    return TakeoutDataMapper.ensureInitialized().encodeMap<TakeoutData>(
      this as TakeoutData,
    );
  }

  TakeoutDataCopyWith<TakeoutData, TakeoutData, TakeoutData> get copyWith =>
      _TakeoutDataCopyWithImpl<TakeoutData, TakeoutData>(
        this as TakeoutData,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return TakeoutDataMapper.ensureInitialized().stringifyValue(
      this as TakeoutData,
    );
  }

  @override
  bool operator ==(Object other) {
    return TakeoutDataMapper.ensureInitialized().equalsValue(
      this as TakeoutData,
      other,
    );
  }

  @override
  int get hashCode {
    return TakeoutDataMapper.ensureInitialized().hashValue(this as TakeoutData);
  }
}

extension TakeoutDataValueCopy<$R, $Out>
    on ObjectCopyWith<$R, TakeoutData, $Out> {
  TakeoutDataCopyWith<$R, TakeoutData, $Out> get $asTakeoutData =>
      $base.as((v, t, t2) => _TakeoutDataCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class TakeoutDataCopyWith<$R, $In extends TakeoutData, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, Comment, CommentCopyWith<$R, Comment, Comment>> get comments;
  ListCopyWith<$R, LiveChat, LiveChatCopyWith<$R, LiveChat, LiveChat>>
  get liveChats;
  MapCopyWith<
    $R,
    String,
    Subscription,
    SubscriptionCopyWith<$R, Subscription, Subscription>
  >
  get subscriptionsByChannelId;
  $R call({
    List<Comment>? comments,
    List<LiveChat>? liveChats,
    Map<String, Subscription>? subscriptionsByChannelId,
  });
  TakeoutDataCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _TakeoutDataCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, TakeoutData, $Out>
    implements TakeoutDataCopyWith<$R, TakeoutData, $Out> {
  _TakeoutDataCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<TakeoutData> $mapper =
      TakeoutDataMapper.ensureInitialized();
  @override
  ListCopyWith<$R, Comment, CommentCopyWith<$R, Comment, Comment>>
  get comments => ListCopyWith(
    $value.comments,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(comments: v),
  );
  @override
  ListCopyWith<$R, LiveChat, LiveChatCopyWith<$R, LiveChat, LiveChat>>
  get liveChats => ListCopyWith(
    $value.liveChats,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(liveChats: v),
  );
  @override
  MapCopyWith<
    $R,
    String,
    Subscription,
    SubscriptionCopyWith<$R, Subscription, Subscription>
  >
  get subscriptionsByChannelId => MapCopyWith(
    $value.subscriptionsByChannelId,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(subscriptionsByChannelId: v),
  );
  @override
  $R call({
    List<Comment>? comments,
    List<LiveChat>? liveChats,
    Map<String, Subscription>? subscriptionsByChannelId,
  }) => $apply(
    FieldCopyWithData({
      if (comments != null) #comments: comments,
      if (liveChats != null) #liveChats: liveChats,
      if (subscriptionsByChannelId != null)
        #subscriptionsByChannelId: subscriptionsByChannelId,
    }),
  );
  @override
  TakeoutData $make(CopyWithData data) => TakeoutData(
    comments: data.get(#comments, or: $value.comments),
    liveChats: data.get(#liveChats, or: $value.liveChats),
    subscriptionsByChannelId: data.get(
      #subscriptionsByChannelId,
      or: $value.subscriptionsByChannelId,
    ),
  );

  @override
  TakeoutDataCopyWith<$R2, TakeoutData, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _TakeoutDataCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

