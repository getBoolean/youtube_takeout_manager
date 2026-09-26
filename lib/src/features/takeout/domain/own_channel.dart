import 'package:dart_mappable/dart_mappable.dart';

part 'own_channel.mapper.dart';

/// A YouTube channel of the Google account a takeout was exported from, as
/// listed in the takeout's `channels/channel.csv`.
@MappableClass()
class OwnChannel with OwnChannelMappable {
  final String channelId;
  final String? title;

  /// "Channel Vanity URL 1 Name": an old custom URL (youtube.com/c/name),
  /// not necessarily the channel's @handle.
  final String? vanityName;

  const OwnChannel({required this.channelId, this.title, this.vanityName});
}
