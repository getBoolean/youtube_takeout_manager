import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Copies an image's URL, e.g. to check one that won't load.
Future<void> copyImageUrl(BuildContext context, String url) async {
  await Clipboard.setData(ClipboardData(text: url));
  if (!context.mounted) return;
  ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(const SnackBar(content: Text('Image URL copied')));
}

/// Offers "Copy image URL" on right-click, and on long press when
/// [longPress] is set. When [url] isn't a web URL, shows [unavailableLabel]
/// instead.
class ImageUrlMenu extends StatefulWidget {
  final String url;
  final bool longPress;
  final String unavailableLabel;
  final Widget child;

  const ImageUrlMenu({
    super.key,
    required this.url,
    this.longPress = false,
    this.unavailableLabel = 'No image URL',
    required this.child,
  });

  @override
  State<ImageUrlMenu> createState() => _ImageUrlMenuState();
}

class _ImageUrlMenuState extends State<ImageUrlMenu> {
  final _controller = MenuController();

  bool get _isWebUrl {
    final scheme = Uri.tryParse(widget.url)?.scheme;
    return scheme == 'https' || scheme == 'http';
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _controller,
      menuChildren: [
        // Inside another menu (e.g. the emoji picker) a click elsewhere in
        // it doesn't count as outside this menu, so close it here.
        TapRegion(onTapOutside: (_) => _controller.close(), child: _item()),
      ],
      child: GestureDetector(
        onSecondaryTapUp: (details) =>
            _controller.open(position: details.localPosition),
        onLongPressStart: widget.longPress
            ? (details) => _controller.open(position: details.localPosition)
            : null,
        child: widget.child,
      ),
    );
  }

  Widget _item() {
    if (!_isWebUrl) {
      return MenuItemButton(
        leadingIcon: const Icon(Icons.link_off),
        child: Text(widget.unavailableLabel),
      );
    }
    return MenuItemButton(
      leadingIcon: const Icon(Icons.link),
      // Only this menu: inside another menu that one stays open.
      closeOnActivate: false,
      onPressed: () {
        _controller.close();
        copyImageUrl(context, widget.url);
      },
      child: const Text('Copy image URL'),
    );
  }
}
