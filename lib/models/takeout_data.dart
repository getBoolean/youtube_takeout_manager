import 'package:dart_mappable/dart_mappable.dart';

import 'comment.dart';
import 'live_chat.dart';
import 'subscription.dart';

part 'takeout_data.mapper.dart';

@MappableClass()
class TakeoutData with TakeoutDataMappable {
  final List<Comment> comments;
  final List<LiveChat> liveChats;
  final Map<String, Subscription> subscriptionsByChannelId;

  const TakeoutData({
    required this.comments,
    required this.liveChats,
    required this.subscriptionsByChannelId,
  });
}
