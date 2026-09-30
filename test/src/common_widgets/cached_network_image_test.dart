import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:youtube_takeout_manager/src/common_widgets/cached_network_image.dart';
import 'package:youtube_takeout_manager/src/common_widgets/fade_in_picture.dart';
import 'package:youtube_takeout_manager/src/storage/image_bytes_cache.dart';

const _url = 'https://i.ytimg.com/vi/abc/mqdefault.jpg';

/// A 1×1 PNG, drawn rather than kept as a binary.
Future<Uint8List> _png() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 1, 1),
    Paint()..color = const Color(0xFFFF0000),
  );
  final image = await recorder.endRecording().toImage(1, 1);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// A cache whose reads fail, as a crashed worker's would.
class _Broken implements ImageBytesCache {
  @override
  Future<Uint8List?> read(String key) => throw StateError('gone');

  @override
  Future<void> write(String key, Uint8List bytes) async {}

  @override
  Future<void> clear() async {}
}

void main() {
  late Uint8List png;
  late int requests;

  setUp(() => requests = 0);

  http.Client client({int status = 200}) => MockClient((_) async {
    requests++;
    return http.Response.bytes(status == 200 ? png : [], status);
  });

  Future<void> load(WidgetTester tester, ImageProvider image) async {
    await tester.runAsync(() async {
      final context = tester.element(find.byType(SizedBox));
      await precacheImage(image, context, onError: (_, _) {});
    });
  }

  Future<void> pumpHost(WidgetTester tester) async {
    png = (await tester.runAsync(_png))!;
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('a picture is downloaded once, then read from the device', (
    tester,
  ) async {
    await pumpHost(tester);
    final cache = MemoryImageBytesCache();

    await load(tester, CachedNetworkImage(_url, cache, client: client()));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    PaintingBinding.instance.imageCache.clear();
    await load(tester, CachedNetworkImage(_url, cache, client: client()));

    expect(requests, 1);
    expect(cache.images, hasLength(1));
  });

  testWidgets("a picture that fails to download isn't kept", (tester) async {
    await pumpHost(tester);
    final cache = MemoryImageBytesCache();

    await load(
      tester,
      CachedNetworkImage(_url, cache, client: client(status: 404)),
    );

    expect(cache.images, isEmpty);
  });

  testWidgets('a cache that fails to read falls back to the network', (
    tester,
  ) async {
    await pumpHost(tester);

    await load(tester, CachedNetworkImage(_url, _Broken(), client: client()));

    expect(requests, 1);
  });

  testWidgets('pictures under a cache scope go through the cache', (
    tester,
  ) async {
    await pumpHost(tester);
    final cache = MemoryImageBytesCache();
    await tester.pumpWidget(
      ImageBytesCacheScope(
        cache: cache,
        child: const MaterialApp(
          home: NetworkPicture(
            url: _url,
            placeholder: SizedBox(),
            width: 40,
            height: 40,
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image)).image;
    expect(image, isA<ResizeImage>());
    expect((image as ResizeImage).imageProvider, isA<CachedNetworkImage>());
  });

  test('keys fit storage: short URLs as they are, long ones shortened', () {
    expect(imageCacheKey(_url), _url);
    final long = 'https://yt3.ggpht.com/${'x' * 400}';
    expect(imageCacheKey(long).length, lessThanOrEqualTo(255));
    expect(imageCacheKey(long), isNot(imageCacheKey('${long}y')));
  });
}
