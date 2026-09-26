// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'live_chat.dart';

class LiveChatMapper extends ClassMapperBase<LiveChat> {
  LiveChatMapper._();

  static LiveChatMapper? _instance;
  static LiveChatMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LiveChatMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'LiveChat';

  static String _$liveChatId(LiveChat v) => v.liveChatId;
  static const Field<LiveChat, String> _f$liveChatId = Field(
    'liveChatId',
    _$liveChatId,
  );
  static String _$channelId(LiveChat v) => v.channelId;
  static const Field<LiveChat, String> _f$channelId = Field(
    'channelId',
    _$channelId,
  );
  static DateTime _$createdAt(LiveChat v) => v.createdAt;
  static const Field<LiveChat, DateTime> _f$createdAt = Field(
    'createdAt',
    _$createdAt,
  );
  static double _$price(LiveChat v) => v.price;
  static const Field<LiveChat, double> _f$price = Field('price', _$price);
  static String? _$currencyCode(LiveChat v) => v.currencyCode;
  static const Field<LiveChat, String> _f$currencyCode = Field(
    'currencyCode',
    _$currencyCode,
    opt: true,
  );
  static String? _$videoId(LiveChat v) => v.videoId;
  static const Field<LiveChat, String> _f$videoId = Field(
    'videoId',
    _$videoId,
    opt: true,
  );
  static String _$rawText(LiveChat v) => v.rawText;
  static const Field<LiveChat, String> _f$rawText = Field('rawText', _$rawText);
  static String _$displayText(LiveChat v) => v.displayText;
  static const Field<LiveChat, String> _f$displayText = Field(
    'displayText',
    _$displayText,
  );

  @override
  final MappableFields<LiveChat> fields = const {
    #liveChatId: _f$liveChatId,
    #channelId: _f$channelId,
    #createdAt: _f$createdAt,
    #price: _f$price,
    #currencyCode: _f$currencyCode,
    #videoId: _f$videoId,
    #rawText: _f$rawText,
    #displayText: _f$displayText,
  };

  static LiveChat _instantiate(DecodingData data) {
    return LiveChat(
      liveChatId: data.dec(_f$liveChatId),
      channelId: data.dec(_f$channelId),
      createdAt: data.dec(_f$createdAt),
      price: data.dec(_f$price),
      currencyCode: data.dec(_f$currencyCode),
      videoId: data.dec(_f$videoId),
      rawText: data.dec(_f$rawText),
      displayText: data.dec(_f$displayText),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static LiveChat fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<LiveChat>(map);
  }

  static LiveChat fromJson(String json) {
    return ensureInitialized().decodeJson<LiveChat>(json);
  }
}

mixin LiveChatMappable {
  String toJson() {
    return LiveChatMapper.ensureInitialized().encodeJson<LiveChat>(
      this as LiveChat,
    );
  }

  Map<String, dynamic> toMap() {
    return LiveChatMapper.ensureInitialized().encodeMap<LiveChat>(
      this as LiveChat,
    );
  }

  LiveChatCopyWith<LiveChat, LiveChat, LiveChat> get copyWith =>
      _LiveChatCopyWithImpl<LiveChat, LiveChat>(
        this as LiveChat,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return LiveChatMapper.ensureInitialized().stringifyValue(this as LiveChat);
  }

  @override
  bool operator ==(Object other) {
    return LiveChatMapper.ensureInitialized().equalsValue(
      this as LiveChat,
      other,
    );
  }

  @override
  int get hashCode {
    return LiveChatMapper.ensureInitialized().hashValue(this as LiveChat);
  }
}

extension LiveChatValueCopy<$R, $Out> on ObjectCopyWith<$R, LiveChat, $Out> {
  LiveChatCopyWith<$R, LiveChat, $Out> get $asLiveChat =>
      $base.as((v, t, t2) => _LiveChatCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class LiveChatCopyWith<$R, $In extends LiveChat, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? liveChatId,
    String? channelId,
    DateTime? createdAt,
    double? price,
    String? currencyCode,
    String? videoId,
    String? rawText,
    String? displayText,
  });
  LiveChatCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _LiveChatCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, LiveChat, $Out>
    implements LiveChatCopyWith<$R, LiveChat, $Out> {
  _LiveChatCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<LiveChat> $mapper =
      LiveChatMapper.ensureInitialized();
  @override
  $R call({
    String? liveChatId,
    String? channelId,
    DateTime? createdAt,
    double? price,
    Object? currencyCode = $none,
    Object? videoId = $none,
    String? rawText,
    String? displayText,
  }) => $apply(
    FieldCopyWithData({
      if (liveChatId != null) #liveChatId: liveChatId,
      if (channelId != null) #channelId: channelId,
      if (createdAt != null) #createdAt: createdAt,
      if (price != null) #price: price,
      if (currencyCode != $none) #currencyCode: currencyCode,
      if (videoId != $none) #videoId: videoId,
      if (rawText != null) #rawText: rawText,
      if (displayText != null) #displayText: displayText,
    }),
  );
  @override
  LiveChat $make(CopyWithData data) => LiveChat(
    liveChatId: data.get(#liveChatId, or: $value.liveChatId),
    channelId: data.get(#channelId, or: $value.channelId),
    createdAt: data.get(#createdAt, or: $value.createdAt),
    price: data.get(#price, or: $value.price),
    currencyCode: data.get(#currencyCode, or: $value.currencyCode),
    videoId: data.get(#videoId, or: $value.videoId),
    rawText: data.get(#rawText, or: $value.rawText),
    displayText: data.get(#displayText, or: $value.displayText),
  );

  @override
  LiveChatCopyWith<$R2, LiveChat, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _LiveChatCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

