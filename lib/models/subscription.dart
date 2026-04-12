import 'package:dart_mappable/dart_mappable.dart';

part 'subscription.mapper.dart';

@MappableClass()
class Subscription with SubscriptionMappable {
  final String channelId;
  final String channelUrl;
  final String channelTitle;

  const Subscription({
    required this.channelId,
    required this.channelUrl,
    required this.channelTitle,
  });
}
