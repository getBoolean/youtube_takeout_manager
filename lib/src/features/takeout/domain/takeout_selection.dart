import 'package:dart_mappable/dart_mappable.dart';

part 'takeout_selection.mapper.dart';

/// Which saved takeout is shown, and the channel last chosen in it.
@MappableClass()
class TakeoutSelection with TakeoutSelectionMappable {
  /// The ID the takeout is saved under.
  final String takeoutId;

  /// The channel last chosen in the takeout, or null to show its main
  /// channel. May no longer be in the takeout, e.g. after a replace.
  final String? channelId;

  const TakeoutSelection({required this.takeoutId, this.channelId});
}
