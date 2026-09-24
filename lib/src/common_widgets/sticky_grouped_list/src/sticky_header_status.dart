part of '../sticky_grouped_list.dart';

/// Where a group's header currently sits relative to the viewport.
@immutable
class StickyHeaderStatus {
  const StickyHeaderStatus({
    this.isPinned = false,
    this.isExpanded = true,
    this.scrollPercentage = 0,
  });

  /// The group starts above the viewport and is still partly visible, so its
  /// header is drawn pinned to the top.
  final bool isPinned;

  final bool isExpanded;

  /// How far the header is scrolled or pushed out of view: 0 while fully in
  /// place, 1 once it is completely gone. Not snapped.
  final double scrollPercentage;

  StickyHeaderStatus copyWith({
    bool? isPinned,
    bool? isExpanded,
    double? scrollPercentage,
  }) => StickyHeaderStatus(
    isPinned: isPinned ?? this.isPinned,
    isExpanded: isExpanded ?? this.isExpanded,
    scrollPercentage: scrollPercentage ?? this.scrollPercentage,
  );

  @override
  bool operator ==(Object other) =>
      other is StickyHeaderStatus &&
      other.isPinned == isPinned &&
      other.isExpanded == isExpanded &&
      other.scrollPercentage == scrollPercentage;

  @override
  int get hashCode => Object.hash(isPinned, isExpanded, scrollPercentage);

  @override
  String toString() =>
      'StickyHeaderStatus(pinned: $isPinned, expanded: $isExpanded, '
      'scrolled: ${scrollPercentage.toStringAsFixed(3)})';
}
