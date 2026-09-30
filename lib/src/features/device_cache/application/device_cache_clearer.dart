import 'package:flutter/painting.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:youtube_takeout_manager/src/storage/storage_providers.dart';

part 'device_cache_clearer.g.dart';

/// Clears the pictures and thumbnails kept on this device. A service:
/// nothing depends on it, so it can read any provider.
@Riverpod(keepAlive: true)
class DeviceCacheClearer extends _$DeviceCacheClearer {
  @override
  void build() {}

  /// Clears the pictures and thumbnails kept on this device, and the ones
  /// held in memory, so they're downloaded again as they're shown.
  /// Everything else loaded from YouTube is kept: video details, lengths
  /// and shapes, picture links, topics and categories.
  Future<void> clear() async {
    await ref.read(imageBytesCacheProvider)?.clear();
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  }
}
