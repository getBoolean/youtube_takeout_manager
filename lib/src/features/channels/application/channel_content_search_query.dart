import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'channel_content_search_query.g.dart';

/// Search text on the channel detail screen, shared by the comments and live
/// chats tabs.
@riverpod
class ChannelContentSearchQuery extends _$ChannelContentSearchQuery {
  @override
  String build() => '';

  void update(String query) => state = query;
}
