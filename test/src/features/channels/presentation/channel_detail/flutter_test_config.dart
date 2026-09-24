import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden comparisons in this directory ignore anti-aliasing noise: a pixel
/// only counts as different when a channel differs by more than
/// [_maxChannelDelta]. Any real change (layout, color, timing) still fails.
const _maxChannelDelta = 1;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final previous = goldenFileComparator;
  if (previous is LocalFileComparator) {
    goldenFileComparator = _AntiAliasTolerantComparator(previous.basedir);
  }
  await testMain();
}

class _AntiAliasTolerantComparator extends LocalFileComparator {
  _AntiAliasTolerantComparator(Uri basedir)
    : super(basedir.resolve('placeholder_test.dart'));

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || await _onlyAntiAliasing(imageBytes, golden)) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }

  Future<bool> _onlyAntiAliasing(Uint8List testBytes, Uri golden) async {
    final test = await _rgba(testBytes);
    final master = await _rgba(
      Uint8List.fromList(await getGoldenBytes(golden)),
    );
    if (test == null || master == null || test.length != master.length) {
      return false;
    }
    for (var i = 0; i < test.length; i++) {
      if ((test[i] - master[i]).abs() > _maxChannelDelta) return false;
    }
    return true;
  }

  Future<Uint8List?> _rgba(Uint8List png) async {
    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData();
    frame.image.dispose();
    codec.dispose();
    return data?.buffer.asUint8List();
  }
}
