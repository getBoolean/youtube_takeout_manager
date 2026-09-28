part of '../sticky_grouped_list.dart';

/// Collapse state and scrolling commands for a [StickyGroupedListView].
///
/// Collapse state lives here rather than in the list so it survives group
/// headers being built and disposed as they scroll in and out of view.
/// Created and disposed by the caller.
class StickyGroupedListController extends ChangeNotifier {
  StickyGroupedListController({Iterable<Object> collapsed = const []})
    : _collapsed = {...collapsed};

  final Set<Object> _collapsed;
  _StickyGroupedListViewState<dynamic, dynamic, dynamic>? _view;

  bool isExpanded(Object groupKey) => !_collapsed.contains(groupKey);

  /// Collapsing or expanding is instant; the scroll offset is left alone.
  void setExpanded(Object groupKey, bool expanded) {
    final changed = expanded
        ? _collapsed.remove(groupKey)
        : _collapsed.add(groupKey);
    if (changed) notifyListeners();
  }

  void toggle(Object groupKey) => setExpanded(groupKey, !isExpanded(groupKey));

  void collapseAll(Iterable<Object> groupKeys) {
    var changed = false;
    for (final key in groupKeys) {
      changed = _collapsed.add(key) || changed;
    }
    if (changed) notifyListeners();
  }

  /// Key of the group whose header is currently pinned, if any.
  Object? get pinnedGroupKey => _view?._pinnedGroupKey;

  /// Key of the group at the top of the list, pinned or not, if any.
  Object? get topGroupKey => _view?._topGroupKey;

  /// Re-sends every live header state's current status through
  /// `updateHeaderState`, for when something outside the list that the
  /// update depends on has changed.
  void refreshHeaderStates() => _view?._refreshHeaderStates();

  /// Scrolls so the item with [itemKey] sits [gap] pixels below its group's
  /// pinned header. Lays out the rows up to the item first if needed.
  ///
  /// Completes with false when the item is unknown or its group collapsed.
  Future<bool> revealItem(
    Object itemKey, {
    double gap = 0,
    Duration duration = Duration.zero,
    Curve curve = Curves.linear,
  }) async =>
      await _view?._revealItem(
        itemKey,
        gap: gap,
        duration: duration,
        curve: curve,
      ) ??
      false;
}
