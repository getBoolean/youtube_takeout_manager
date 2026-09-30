import 'package:flutter/material.dart';

/// One choice of an [AdaptiveSegmentedButton]; [key] goes on its label.
class AdaptiveSegment<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Key? key;

  const AdaptiveSegment({
    required this.value,
    required this.label,
    this.icon,
    this.key,
  });
}

/// A single-choice [SegmentedButton] that sits in a row when every label
/// fits, and stacks its choices when they don't, so no label is squeezed
/// or cut.
class AdaptiveSegmentedButton<T extends Object> extends StatelessWidget {
  final List<AdaptiveSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  const AdaptiveSegmentedButton({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  /// Room a segment needs besides its label: padding, the selected check
  /// and the border.
  static const _segmentChrome = 56.0;
  static const _iconWidth = 26.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = Theme.of(context).textTheme.labelLarge;
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

        final needed = segments.fold(
          0.0,
          (sum, s) =>
              sum +
              _segmentChrome +
              textWidth(s.label) +
              (s.icon == null ? 0 : _iconWidth),
        );
        final fits = needed <= constraints.maxWidth;
        return SegmentedButton<T>(
          direction: fits ? Axis.horizontal : Axis.vertical,
          showSelectedIcon: fits,
          segments: [
            for (final s in segments)
              ButtonSegment(
                value: s.value,
                icon: s.icon == null ? null : Icon(s.icon),
                label: Text(key: s.key, s.label, textAlign: TextAlign.center),
              ),
          ],
          selected: {selected},
          onSelectionChanged: (values) => onChanged(values.single),
        );
      },
    );
  }
}
