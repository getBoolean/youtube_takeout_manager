import 'takeout_data.dart';

/// A saved takeout's data, with the ID it's saved under.
///
/// Compared by identity: comparing whole takeouts item by item on every
/// update would be slow, and each load makes a new one anyway.
class LoadedTakeout {
  final String id;
  final TakeoutData data;

  const LoadedTakeout({required this.id, required this.data});
}
