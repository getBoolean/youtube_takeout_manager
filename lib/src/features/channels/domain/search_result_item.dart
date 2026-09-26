import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';

/// A comment or live chat found by the cross-channel search, with the
/// channel it's listed under.
///
/// [channelId] is passed explicitly rather than read from the underlying
/// record because the rest of the app addresses channels by the video's
/// channelId (from YouTube metadata), which may differ from the value stored
/// on the CSV row.
final class SearchResultItem {
  final Interaction item;
  final String channelId;

  const SearchResultItem(this.item, {required this.channelId});
}
