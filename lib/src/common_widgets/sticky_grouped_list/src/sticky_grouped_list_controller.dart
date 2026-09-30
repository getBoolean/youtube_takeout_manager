part of '../sticky_grouped_list.dart';

/// Collapse state and scrolling commands for a [StickyGroupedListView].
///
/// Collapse state lives here rather than in the list so it survives group
/// headers being built and disposed as they scroll in and out of view.
/// Created and disposed by the caller.
///
/// Groups are expanded unless [expandedByDefault] is false; the groups set
/// otherwise are kept apart, so collapsing or expanding every group is one
/// step however many there are, and covers groups that appear later.
class StickyGroupedListController extends ChangeNotifier {
  StickyGroupedListController({
    Iterable<Object> collapsed = const [],
    bool expandedByDefault = true,
  }) : _expandedByDefault = expandedByDefault,
       _exceptions = {if (expandedByDefault) ...collapsed};

  bool _expandedByDefault;

  /// The groups whose state isn't the default.
  final Set<Object> _exceptions;
  _StickyGroupedListViewState<dynamic, dynamic, dynamic>? _view;

  /// Whether groups not set one way or the other are expanded.
  bool get expandedByDefault => _expandedByDefault;

  bool isExpanded(Object groupKey) =>
      _expandedByDefault != _exceptions.contains(groupKey);

  /// Collapsing or expanding is instant; the scroll offset is left alone.
  void setExpanded(Object groupKey, bool expanded) {
    if (_setExpanded(groupKey, expanded)) notifyListeners();
  }

  void toggle(Object groupKey) => setExpanded(groupKey, !isExpanded(groupKey));

  void collapseAll(Iterable<Object> groupKeys) {
    var changed = false;
    for (final key in groupKeys) {
      changed = _setExpanded(key, false) || changed;
    }
    if (changed) notifyListeners();
  }

  void expandAll(Iterable<Object> groupKeys) {
    var changed = false;
    for (final key in groupKeys) {
      changed = _setExpanded(key, true) || changed;
    }
    if (changed) notifyListeners();
  }

  /// Expands or collapses every group, including ones that appear later.
  void setAllExpanded(bool expanded) {
    if (_expandedByDefault == expanded && _exceptions.isEmpty) return;
    _expandedByDefault = expanded;
    _exceptions.clear();
    notifyListeners();
  }

  /// Whether it changed.
  bool _setExpanded(Object groupKey, bool expanded) =>
      expanded == _expandedByDefault
      ? _exceptions.remove(groupKey)
      : _exceptions.add(groupKey);

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
