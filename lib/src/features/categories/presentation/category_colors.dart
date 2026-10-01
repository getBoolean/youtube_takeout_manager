import 'package:flutter/material.dart';

/// Each category's colour, light and dark: the dataviz palette's
/// categorical slots in their validated order, assigned in YouTube's
/// category order, checked against the app's surfaces for colour-blind
/// separation. The name and emoji always show beside it, so colour is
/// never the only cue, and text never wears it.
const _light = {
  'Gaming': Color(0xFF2A78D6),
  'Music': Color(0xFFEB6834),
  'Sports': Color(0xFF1BAF7A),
  'Entertainment': Color(0xFFEDA100),
  'Lifestyle': Color(0xFFE87BA4),
  'Society': Color(0xFF008300),
  'Knowledge': Color(0xFF4A3AA7),
};

const _dark = {
  'Gaming': Color(0xFF3987E5),
  'Music': Color(0xFFD95926),
  'Sports': Color(0xFF199E70),
  'Entertainment': Color(0xFFC98500),
  'Lifestyle': Color(0xFFD55181),
  'Society': Color(0xFF008300),
  'Knowledge': Color(0xFF9085E9),
};

/// Channels with no category, or one of no known category: neutral grey.
const _uncategorized = Color(0xFF898781);

/// The colour of the category [parent] (none for no category).
Color categoryColor(String? parent, Brightness brightness) =>
    (brightness == Brightness.light ? _light : _dark)[parent] ?? _uncategorized;

/// A pill's fill for the category [parent]: its colour, faint, over the
/// surface, so on-surface text keeps its contrast.
Color categoryTint(String? parent, ColorScheme scheme) => Color.alphaBlend(
  categoryColor(
    parent,
    scheme.brightness,
  ).withValues(alpha: scheme.brightness == Brightness.light ? 0.18 : 0.30),
  scheme.surfaceContainerLow,
);

/// The mark of a name or category AI made, told to screen readers.
class AiMark extends StatelessWidget {
  final double size;
  final Color? color;

  const AiMark({super.key, this.size = 16, this.color});

  @override
  Widget build(BuildContext context) => Icon(
    Icons.auto_awesome,
    size: size,
    color: color,
    semanticLabel: 'made by AI',
  );
}
