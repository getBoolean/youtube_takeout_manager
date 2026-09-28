import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/common_widgets/fade_in_picture.dart';

/// A 1×1 transparent PNG, fresh each time so no test finds it cached.
MemoryImage _picture() => MemoryImage(
  Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]),
);

const _placeholder = Text('placeholder');

Widget _app(ImageProvider image, {bool animationsOff = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: animationsOff),
    child: Center(
      child: FadeInPicture(
        image: image,
        placeholder: _placeholder,
        width: 40,
        height: 40,
      ),
    ),
  ),
);

/// How opaque the picture is drawn, whatever fades it.
double _shown(WidgetTester tester) {
  var opacity = 1.0;
  for (final fade in tester.widgetList<FadeTransition>(
    find.ancestor(
      of: find.byType(RawImage),
      matching: find.byType(FadeTransition),
    ),
  )) {
    opacity *= fade.opacity.value;
  }
  return opacity;
}

/// Lets [image] decode, which takes real time.
Future<void> _load(WidgetTester tester, ImageProvider image) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(_app(image));
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
}

void main() {
  testWidgets('shows its placeholder until the picture has loaded, then '
      'fades the picture in', (tester) async {
    final image = _picture();
    await tester.pumpWidget(_app(image));

    expect(find.text('placeholder'), findsOneWidget);
    expect(_shown(tester), 0);

    await _load(tester, image);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(_shown(tester), inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(_shown(tester), 1);
  });

  testWidgets('a picture already loaded shows at once', (tester) async {
    final image = _picture();
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => precacheImage(image, tester.element(find.byType(SizedBox))),
    );
    await tester.pumpWidget(_app(image));

    expect(_shown(tester), 1);
    expect(find.text('placeholder'), findsNothing);
  });

  testWidgets('with animations off, the picture shows at once when loaded', (
    tester,
  ) async {
    final image = _picture();
    await tester.runAsync(() async {
      await tester.pumpWidget(_app(image, animationsOff: true));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    expect(_shown(tester), 1);
  });

  testWidgets("a picture that won't load leaves the placeholder", (
    tester,
  ) async {
    final broken = MemoryImage(Uint8List.fromList(const [1, 2, 3]));
    await _load(tester, broken);
    await tester.pump();

    expect(find.text('placeholder'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
