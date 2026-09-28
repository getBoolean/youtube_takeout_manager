import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// How long a picture takes to fade in once it has loaded.
const _fadeIn = Duration(milliseconds: 150);

/// A picture that shows [placeholder] until it has loaded, then fades in
/// over it: at once when it had already loaded, or when animations are off.
/// [placeholder] stays when it won't load.
class FadeInPicture extends StatelessWidget {
  final ImageProvider image;
  final Widget placeholder;
  final double? width;
  final double? height;
  final BoxFit fit;

  const FadeInPicture({
    super.key,
    required this.image,
    required this.placeholder,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _fadeIn;
    return Image(
      image: image,
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return Stack(
          fit: StackFit.passthrough,
          children: [
            placeholder,
            AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: duration,
              curve: Curves.easeOut,
              child: child,
            ),
          ],
        );
      },
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

/// The picture at [url], faded in over [placeholder] as [FadeInPicture]
/// does, and decoded no wider than [decodeWidth] (by default [width]), which
/// saves memory and drawing time in long lists.
class NetworkPicture extends StatelessWidget {
  final String url;
  final Widget placeholder;

  /// Its size, when given; otherwise it fills its parent.
  final double? width;
  final double? height;

  /// The widest it's shown, in logical pixels.
  final double? decodeWidth;
  final BoxFit fit;

  /// Whether the web app shows it as an HTML image, for hosts that won't
  /// hand their pictures to other sites' code. Those can't be resized.
  final bool htmlElementOnWeb;

  const NetworkPicture({
    super.key,
    required this.url,
    required this.placeholder,
    this.width,
    this.height,
    this.decodeWidth,
    this.fit = BoxFit.cover,
    this.htmlElementOnWeb = false,
  });

  @override
  Widget build(BuildContext context) {
    final network = NetworkImage(
      url,
      webHtmlElementStrategy: htmlElementOnWeb
          ? WebHtmlElementStrategy.prefer
          : WebHtmlElementStrategy.never,
    );
    final shownWidth = decodeWidth ?? width;
    final resize = shownWidth != null && !(kIsWeb && htmlElementOnWeb);
    return FadeInPicture(
      image: ResizeImage.resizeIfNeeded(
        resize
            ? (shownWidth * MediaQuery.devicePixelRatioOf(context)).ceil()
            : null,
        null,
        network,
      ),
      placeholder: placeholder,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
