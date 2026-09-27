import 'package:flutter/material.dart';

import 'package:youtube_takeout_manager/src/common_widgets/cue_motion.dart';

/// One tab of a [CountedTabBar]: what it shows and how many things are in it.
class CountedTab {
  final IconData icon;
  final String label;
  final int count;

  const CountedTab({
    required this.icon,
    required this.label,
    required this.count,
  });
}

/// A tab's full label, "Label (count)", with the count animating as it
/// changes.
class CountedTabLabel extends StatelessWidget {
  final String prefix;
  final int count;

  const CountedTabLabel({super.key, required this.prefix, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [Text('$prefix ('), AnimatedCountText(count), const Text(')')],
    );
  }
}

/// Tabs with counts. Shows the full labels when they fit, then icons with
/// counts, then just icons, so every tab always stays on screen. A scrolling
/// tab bar would hide some, and can't be scrolled with a mouse.
class CountedTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<CountedTab> tabs;

  const CountedTabBar({
    super.key,
    required this.controller,
    required this.tabs,
  });

  static const _iconSize = 20.0;
  static const _iconGap = 6.0;

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final style =
            TabBarTheme.of(context).labelStyle ??
            Theme.of(context).textTheme.titleSmall;
        final scaler = MediaQuery.textScalerOf(context);
        final direction = Directionality.of(context);
        double textWidth(String text) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textScaler: scaler,
            textDirection: direction,
            maxLines: 1,
          )..layout();
          final width = painter.width;
          painter.dispose();
          return width;
        }

        // Each tab gets an equal share of the bar, less its label padding.
        final room =
            constraints.maxWidth / tabs.length - kTabLabelPadding.horizontal;
        final labelsFit = tabs.every(
          (t) => textWidth('${t.label} (${t.count})') <= room,
        );
        final countsFit = tabs.every(
          (t) => _iconSize + _iconGap + textWidth('${t.count}') <= room,
        );

        return TabBar(
          controller: controller,
          // In the narrowest windows the padding alone would push icons over.
          labelPadding: _iconSize <= room ? null : EdgeInsets.zero,
          tabs: [
            for (final tab in tabs)
              Tab(
                child: labelsFit
                    ? CountedTabLabel(prefix: tab.label, count: tab.count)
                    : Tooltip(
                        message: '${tab.label} (${tab.count})',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(tab.icon, size: _iconSize),
                            if (countsFit) ...[
                              const SizedBox(width: _iconGap),
                              AnimatedCountText(tab.count),
                            ],
                          ],
                        ),
                      ),
              ),
          ],
        );
      },
    );
  }
}
