import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/deletion/presentation/queue_panel/deletion_queue_layout.dart';

void main() {
  DeletionQueueLayout layout(double width, TargetPlatform platform) =>
      deletionQueueLayoutFor(width: width, platform: platform);

  test('phones get the bottom bar', () {
    expect(layout(400, TargetPlatform.android), DeletionQueueLayout.bottomBar);
    expect(layout(599, TargetPlatform.iOS), DeletionQueueLayout.bottomBar);
  });

  test('desktop never gets the bottom bar', () {
    for (final platform in [
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    ]) {
      expect(layout(1280, platform), DeletionQueueLayout.docked);
      expect(layout(960, platform), DeletionQueueLayout.docked);
      expect(layout(959, platform), DeletionQueueLayout.strip);
      expect(layout(600, platform), DeletionQueueLayout.strip);
      expect(layout(599, platform), DeletionQueueLayout.appBarIcon);
      expect(layout(320, platform), DeletionQueueLayout.appBarIcon);
    }
  });

  test('tablets use the desktop layouts', () {
    expect(layout(800, TargetPlatform.android), DeletionQueueLayout.strip);
    expect(layout(1024, TargetPlatform.iOS), DeletionQueueLayout.docked);
  });
}
