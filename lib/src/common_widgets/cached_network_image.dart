import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'package:youtube_takeout_manager/src/storage/image_bytes_cache.dart';

/// The picture at [url], read from [cache] when kept there, else downloaded
/// and kept for next time. A cache that can't be read is skipped; only
/// bytes that show as a picture are kept, and kept bytes that no longer do
/// are fetched again.
class CachedNetworkImage extends ImageProvider<CachedNetworkImage> {
  final String url;
  final ImageBytesCache cache;
  final http.Client? client;

  static final _client = http.Client();

  const CachedNetworkImage(this.url, this.cache, {this.client});

  @override
  Future<CachedNetworkImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    CachedNetworkImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _load(decode),
    scale: 1,
    debugLabel: url,
  );

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final key = imageCacheKey(url);
    if (await _read(key) case final kept?) {
      try {
        return await decode(await ui.ImmutableBuffer.fromUint8List(kept));
      } on Object {
        // No longer a picture: fetched again, and replaced.
      }
    }
    final bytes = await _download();
    final codec = await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    // Kept only once it shows as a picture; showing it doesn't wait.
    unawaited(cache.write(key, bytes).catchError((Object _) {}));
    return codec;
  }

  /// What [cache] holds for [key]; none when it can't be read.
  Future<Uint8List?> _read(String key) async {
    try {
      return await cache.read(key);
    } on Object {
      return null;
    }
  }

  /// The picture's bytes, or an error for a failed or empty answer.
  Future<Uint8List> _download() async {
    final uri = Uri.parse(url);
    final response = await (client ?? _client).get(uri);
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw NetworkImageLoadException(
        statusCode: response.statusCode,
        uri: uri,
      );
    }
    return response.bodyBytes;
  }

  @override
  bool operator ==(Object other) =>
      other is CachedNetworkImage &&
      other.url == url &&
      identical(other.cache, cache);

  @override
  int get hashCode => Object.hash(url, identityHashCode(cache));
}

/// Gives the pictures below it [cache] to keep their bytes in; none leaves
/// them to the network (and the browser's cache).
class ImageBytesCacheScope extends InheritedWidget {
  final ImageBytesCache? cache;

  const ImageBytesCacheScope({
    super.key,
    required this.cache,
    required super.child,
  });

  static ImageBytesCache? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ImageBytesCacheScope>()?.cache;

  @override
  bool updateShouldNotify(ImageBytesCacheScope oldWidget) =>
      !identical(oldWidget.cache, cache);
}
