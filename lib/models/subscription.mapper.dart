// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'subscription.dart';

class SubscriptionMapper extends ClassMapperBase<Subscription> {
  SubscriptionMapper._();

  static SubscriptionMapper? _instance;
  static SubscriptionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SubscriptionMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'Subscription';

  static String _$channelId(Subscription v) => v.channelId;
  static const Field<Subscription, String> _f$channelId = Field(
    'channelId',
    _$channelId,
  );
  static String _$channelUrl(Subscription v) => v.channelUrl;
  static const Field<Subscription, String> _f$channelUrl = Field(
    'channelUrl',
    _$channelUrl,
  );
  static String _$channelTitle(Subscription v) => v.channelTitle;
  static const Field<Subscription, String> _f$channelTitle = Field(
    'channelTitle',
    _$channelTitle,
  );

  @override
  final MappableFields<Subscription> fields = const {
    #channelId: _f$channelId,
    #channelUrl: _f$channelUrl,
    #channelTitle: _f$channelTitle,
  };

  static Subscription _instantiate(DecodingData data) {
    return Subscription(
      channelId: data.dec(_f$channelId),
      channelUrl: data.dec(_f$channelUrl),
      channelTitle: data.dec(_f$channelTitle),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Subscription fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Subscription>(map);
  }

  static Subscription fromJson(String json) {
    return ensureInitialized().decodeJson<Subscription>(json);
  }
}

mixin SubscriptionMappable {
  String toJson() {
    return SubscriptionMapper.ensureInitialized().encodeJson<Subscription>(
      this as Subscription,
    );
  }

  Map<String, dynamic> toMap() {
    return SubscriptionMapper.ensureInitialized().encodeMap<Subscription>(
      this as Subscription,
    );
  }

  SubscriptionCopyWith<Subscription, Subscription, Subscription> get copyWith =>
      _SubscriptionCopyWithImpl<Subscription, Subscription>(
        this as Subscription,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SubscriptionMapper.ensureInitialized().stringifyValue(
      this as Subscription,
    );
  }

  @override
  bool operator ==(Object other) {
    return SubscriptionMapper.ensureInitialized().equalsValue(
      this as Subscription,
      other,
    );
  }

  @override
  int get hashCode {
    return SubscriptionMapper.ensureInitialized().hashValue(
      this as Subscription,
    );
  }
}

extension SubscriptionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, Subscription, $Out> {
  SubscriptionCopyWith<$R, Subscription, $Out> get $asSubscription =>
      $base.as((v, t, t2) => _SubscriptionCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SubscriptionCopyWith<$R, $In extends Subscription, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? channelId, String? channelUrl, String? channelTitle});
  SubscriptionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SubscriptionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Subscription, $Out>
    implements SubscriptionCopyWith<$R, Subscription, $Out> {
  _SubscriptionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Subscription> $mapper =
      SubscriptionMapper.ensureInitialized();
  @override
  $R call({String? channelId, String? channelUrl, String? channelTitle}) =>
      $apply(
        FieldCopyWithData({
          if (channelId != null) #channelId: channelId,
          if (channelUrl != null) #channelUrl: channelUrl,
          if (channelTitle != null) #channelTitle: channelTitle,
        }),
      );
  @override
  Subscription $make(CopyWithData data) => Subscription(
    channelId: data.get(#channelId, or: $value.channelId),
    channelUrl: data.get(#channelUrl, or: $value.channelUrl),
    channelTitle: data.get(#channelTitle, or: $value.channelTitle),
  );

  @override
  SubscriptionCopyWith<$R2, Subscription, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SubscriptionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

