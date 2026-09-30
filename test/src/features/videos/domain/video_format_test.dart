import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/videos/domain/video_format.dart';

VideoFormat _format(String duration, {int? width, int? height}) =>
    VideoFormat.fromApi(
      duration: duration,
      embedWidth: width?.toString(),
      embedHeight: height?.toString(),
    );

void main() {
  group("a Short, by YouTube's rule", () {
    test('is a tall video of three minutes or less', () {
      expect(_format('PT45S', width: 270, height: 480).isShort, isTrue);
      expect(_format('PT3M', width: 270, height: 480).isShort, isTrue);
    });

    test('can be square', () {
      expect(_format('PT1M', width: 480, height: 480).isShort, isTrue);
    });

    test('is never a wide video, however short', () {
      expect(_format('PT30S', width: 480, height: 270).isShort, isFalse);
    });

    test('is never longer than three minutes', () {
      expect(_format('PT3M1S', width: 270, height: 480).isShort, isFalse);
    });

    test('is not a video whose shape is unknown', () {
      expect(_format('PT30S').isShort, isFalse);
    });

    test('is not a live stream, which has no length', () {
      expect(_format('P0D', width: 270, height: 480).isShort, isFalse);
    });
  });

  test('lengths read hours, minutes and seconds, and days', () {
    expect(parseIsoDuration('PT1H2M3S'), 3723);
    expect(parseIsoDuration('PT15M'), 900);
    expect(parseIsoDuration('P1DT1S'), 86401);
    expect(parseIsoDuration('P0D'), 0);
    expect(parseIsoDuration('soon'), isNull);
  });

  test('a format is kept and read back the same', () {
    for (final format in [
      _format('PT45S', width: 270, height: 480),
      _format('PT10M', width: 480, height: 270),
      _format('PT30S'),
    ]) {
      final back = VideoFormat.fromJson(format.toJson());
      expect((back.seconds, back.shape), (format.seconds, format.shape));
    }
  });
}
