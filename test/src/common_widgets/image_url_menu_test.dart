import 'package:cue/cue.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/common_widgets/image_url_menu.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/video_group.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/channel_detail/video_group_header.dart';
import 'package:youtube_takeout_manager/src/features/videos/application/video_providers.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video.dart';

const _thumbnail = 'https://i.ytimg.com/vi/v1/hqdefault.jpg';

class _FakeVideoMetadata extends VideoMetadata {
  @override
  Stream<Map<String, Video>> build() => Stream.value({
    'v1': const Video(
      videoId: 'v1',
      channelId: 'c',
      title: 'Stream',
      thumbnailUrl: _thumbnail,
    ),
  });
}

void main() {
  late List<String> copied;

  setUp(() => copied = []);

  void mockClipboard(WidgetTester tester) {
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
  }

  Future<void> rightClick(WidgetTester tester, Finder finder) async {
    await tester.tap(
      finder,
      buttons: kSecondaryMouseButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
  }

  const box = ColoredBox(
    color: Colors.orange,
    child: SizedBox.square(dimension: 40),
  );

  testWidgets('right-click copies the image URL', (tester) async {
    mockClipboard(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ImageUrlMenu(url: _thumbnail, child: box),
        ),
      ),
    );

    await rightClick(tester, find.byType(ImageUrlMenu));
    await tester.tap(find.text('Copy image URL'));
    await tester.pumpAndSettle();

    expect(copied, [_thumbnail]);
    expect(find.text('Image URL copied'), findsOneWidget);
  });

  testWidgets('long press opens the menu only when asked', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ImageUrlMenu(url: _thumbnail, child: box),
              ImageUrlMenu(url: _thumbnail, longPress: true, child: box),
            ],
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(ImageUrlMenu).first);
    await tester.pumpAndSettle();
    expect(find.text('Copy image URL'), findsNothing);

    await tester.longPress(find.byType(ImageUrlMenu).last);
    await tester.pumpAndSettle();
    expect(find.text('Copy image URL'), findsOneWidget);
  });

  testWidgets('a video thumbnail offers its URL', (tester) async {
    mockClipboard(tester);
    final motion = CueController(vsync: tester, motion: const Spring.smooth());
    addTearDown(motion.dispose);
    var expanded = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [videoMetadataProvider.overrideWith(_FakeVideoMetadata.new)],
        child: MaterialApp(
          home: Scaffold(
            body: VideoGroupHeader(
              group: const VideoGroup.video('v1', []),
              compactMotion: motion,
              isExpanded: false,
              selectionMode: false,
              allSelected: false,
              someSelected: false,
              onToggleGroupSelection: () {},
              onToggleExpanded: () => expanded++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await rightClick(tester, find.byType(ImageUrlMenu));
    await tester.tap(find.text('Copy image URL'));
    await tester.pumpAndSettle();

    expect(copied, [_thumbnail]);
    expect(expanded, 0); // the header's own tap didn't fire
  });
}
