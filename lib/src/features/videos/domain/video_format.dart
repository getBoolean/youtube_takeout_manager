/// A video's shape, told by its player's size.
enum VideoShape { wide, square, tall }

/// A video's length and shape, from the YouTube API, to tell Shorts from
/// other videos: YouTube has no field saying which is which.
class VideoFormat {
  /// Its length; 0 for a live stream, which has none.
  final int seconds;

  /// Null when YouTube doesn't know it.
  final VideoShape? shape;

  const VideoFormat({required this.seconds, this.shape});

  /// The longest a Short can be.
  static const shortMaxSeconds = 180;

  /// Whether it's a Short, by YouTube's rule since October 2024: square or
  /// tall, and three minutes or less.
  bool get isShort =>
      seconds > 0 &&
      seconds <= shortMaxSeconds &&
      (shape == VideoShape.tall || shape == VideoShape.square);

  /// From a `videos.list` answer: `contentDetails.duration`, and the
  /// player's `embedWidth` and `embedHeight`, which keep the video's shape.
  factory VideoFormat.fromApi({
    String? duration,
    String? embedWidth,
    String? embedHeight,
  }) => VideoFormat(
    seconds: duration == null ? 0 : parseIsoDuration(duration) ?? 0,
    shape: shapeOf(
      int.tryParse(embedWidth ?? ''),
      int.tryParse(embedHeight ?? ''),
    ),
  );

  /// Kept compactly: tens of thousands are stored.
  List<int> toJson() => [seconds, shape?.index ?? -1];

  factory VideoFormat.fromJson(List<dynamic> json) {
    final shape = json.length > 1 ? json[1] as int : -1;
    return VideoFormat(
      seconds: json[0] as int,
      shape: shape >= 0 && shape < VideoShape.values.length
          ? VideoShape.values[shape]
          : null,
    );
  }
}

/// The shape of a [width] by [height] player, or null without both.
VideoShape? shapeOf(int? width, int? height) {
  if (width == null || height == null || width <= 0 || height <= 0) {
    return null;
  }
  final ratio = height / width;
  if (ratio > 1.05) return VideoShape.tall;
  if (ratio < 0.95) return VideoShape.wide;
  return VideoShape.square;
}

/// The seconds in an ISO 8601 [duration] such as `PT1H2M3S` or `P1DT1S`, or
/// null when it isn't one.
int? parseIsoDuration(String duration) {
  final match = _isoDuration.firstMatch(duration);
  if (match == null) return null;
  int part(int group) => int.tryParse(match[group] ?? '') ?? 0;
  return part(1) * 86400 + part(2) * 3600 + part(3) * 60 + part(4);
}

final _isoDuration = RegExp(
  r'^P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$',
);
