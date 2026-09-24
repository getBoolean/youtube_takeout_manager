part of '../sticky_grouped_list.dart';

typedef StickyHeaderBuilder<G, S> =
    Widget Function(
      BuildContext context,
      G group,
      S headerState,
      StickyHeaderStatus status,
    );

typedef StickyItemBuilder<G, I> =
    Widget Function(BuildContext context, G group, I item, int index);

typedef CreateHeaderState<G, S> =
    S Function(G group, StickyHeaderStatus status, TickerProvider vsync);

typedef UpdateHeaderState<G, S> =
    void Function(G group, S headerState, StickyHeaderStatus status);

/// A vertically scrolling list of groups `G` holding items `I`, with sticky,
/// collapsible headers. See the library documentation.
///
/// [headerBuilder] builds both a group's in-list header and its pinned copy;
/// they share one header state `S`, created by [createHeaderState] when the
/// group's header is first needed and disposed by [disposeHeaderState] once
/// it's neither built nor pinnable. [updateHeaderState] runs during layout on
/// the frame a group's [StickyHeaderStatus] changes. The status passed to
/// [headerBuilder] can lag it by a frame for pin changes.
class StickyGroupedListView<G, I, S> extends StatefulWidget {
  const StickyGroupedListView({
    super.key,
    required this.groups,
    required this.groupKey,
    required this.itemsOf,
    required this.itemKey,
    required this.headerBuilder,
    required this.itemBuilder,
    required this.createHeaderState,
    required this.updateHeaderState,
    required this.disposeHeaderState,
    required this.controller,
    required this.scrollController,
    this.scrollCacheExtent,
    this.trailing,
    this.keepAlive = false,
  });

  final List<G> groups;
  final Object Function(G group) groupKey;
  final List<I> Function(G group) itemsOf;
  final Object Function(I item) itemKey;
  final StickyHeaderBuilder<G, S> headerBuilder;
  final StickyItemBuilder<G, I> itemBuilder;
  final CreateHeaderState<G, S> createHeaderState;
  final UpdateHeaderState<G, S> updateHeaderState;
  final void Function(S headerState) disposeHeaderState;
  final StickyGroupedListController controller;
  final ScrollController scrollController;
  final ScrollCacheExtent? scrollCacheExtent;

  /// Sliver placed after the last group, e.g. bottom padding.
  final Widget? trailing;

  /// Keeps the list alive in a lazily built parent such as a `TabBarView`.
  final bool keepAlive;

  @override
  State<StickyGroupedListView<G, I, S>> createState() =>
      _StickyGroupedListViewState<G, I, S>();
}

class _StickyGroupedListViewState<G, I, S>
    extends State<StickyGroupedListView<G, I, S>>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin
    implements _StickyLayoutHost, _RowEstimator {
  late GroupRows _rows;
  late Map<Object, int> _groupIndexByKey;
  Map<Object, (int, int)>? _itemPositionByKey;

  @override
  final _LayoutFacts facts = _LayoutFacts();

  final Map<Object, S> _headerStates = {};

  /// Status each header state was last created or updated with.
  final Map<Object, StickyHeaderStatus> _applied = {};

  /// Latest status computed by layout, for [StickyGroupedListView.headerBuilder].
  final Map<Object, StickyHeaderStatus> _statuses = {};

  /// Status each header was last built with; a rebuild is scheduled when
  /// layout changes its pinned or expanded state.
  final Map<Object, StickyHeaderStatus> _builtStatuses = {};

  final Map<int, double> _pinnableHeights = {};

  /// Height each group's header row had when it was last laid out.
  final Map<Object, double> _headerRowExtents = {};

  /// Groups whose headers the pinnable slots hold.
  Set<int> _pinnableGroups = {};

  /// Extent of every row laid out so far, keyed like the rows, for
  /// estimating where unmeasured rows sit.
  final Map<Object, double> _measuredExtents = {};
  (double, int) _headerExtentSum = (0, 0);
  (double, int) _itemExtentSum = (0, 0);
  bool _rebuildScheduled = false;
  bool _pruneScheduled = false;

  @override
  bool get wantKeepAlive => widget.keepAlive;

  Object? get _pinnedGroupKey {
    final group = facts.pinnedGroup;
    return group == null || group >= widget.groups.length
        ? null
        : widget.groupKey(widget.groups[group]);
  }

  @override
  void initState() {
    super.initState();
    _buildRows();
    _attach(widget.controller);
  }

  @override
  void didUpdateWidget(StickyGroupedListView<G, I, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detach(oldWidget.controller);
      _attach(widget.controller);
    }
    if (oldWidget.groups != widget.groups ||
        oldWidget.controller != widget.controller) {
      _buildRows();
    }
  }

  @override
  void dispose() {
    _detach(widget.controller);
    for (final state in _headerStates.values) {
      widget.disposeHeaderState(state);
    }
    super.dispose();
  }

  void _attach(StickyGroupedListController controller) {
    controller
      .._view = this
      ..addListener(_onCollapseChanged);
  }

  void _detach(StickyGroupedListController controller) {
    controller.removeListener(_onCollapseChanged);
    if (identical(controller._view, this)) controller._view = null;
  }

  void _onCollapseChanged() => setState(_buildRows);

  void _buildRows() {
    final groups = widget.groups;
    _groupIndexByKey = {
      for (var g = 0; g < groups.length; g++) widget.groupKey(groups[g]): g,
    };
    _itemPositionByKey = null;
    _rows = GroupRows([
      for (final group in groups) widget.itemsOf(group).length,
    ], (g) => widget.controller.isExpanded(widget.groupKey(groups[g])));
  }

  Map<Object, (int, int)> get _itemPositions => _itemPositionByKey ??= {
    for (var g = 0; g < widget.groups.length; g++)
      for (final (i, item) in widget.itemsOf(widget.groups[g]).indexed)
        widget.itemKey(item): (g, i),
  };

  // ---------------------------------------------------------------------------
  // Building
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CustomScrollView(
      controller: widget.scrollController,
      scrollCacheExtent: widget.scrollCacheExtent,
      slivers: [
        _StickyGroupedSliver(
          host: this,
          list: _LazySliverList(
            estimator: this,
            delegate: SliverChildBuilderDelegate(
              _buildRow,
              childCount: _rows.length,
              findChildIndexCallback: _indexOfRowKey,
            ),
          ),
          pinnableHeaderBuilder: (context, group) => KeyedSubtree(
            key: ValueKey(('pinned', widget.groupKey(widget.groups[group]))),
            child: _buildHeader(context, group),
          ),
        ),
        ?widget.trailing,
      ],
    );
  }

  Widget _buildRow(BuildContext context, int index) {
    switch (_rows.rowAt(index)) {
      case HeaderRow(:final group):
        return _HeaderRowSlot(
          key: ValueKey(('header', widget.groupKey(widget.groups[group]))),
          group: group,
          facts: facts,
          child: _buildHeader(context, group),
        );
      case ItemRow(:final group, :final item):
        final g = widget.groups[group];
        final value = widget.itemsOf(g)[item];
        return KeyedSubtree(
          key: ValueKey(('item', widget.itemKey(value))),
          child: widget.itemBuilder(context, g, value, item),
        );
    }
  }

  int? _indexOfRowKey(Key key) {
    if (key is! ValueKey<(String, Object)>) return null;
    final (kind, value) = key.value;
    if (kind == 'header') {
      final group = _groupIndexByKey[value];
      return group == null ? null : _rows.headerRowOf(group);
    }
    final position = _itemPositions[value];
    return position == null ? null : _rows.rowOfItem(position.$1, position.$2);
  }

  Widget _buildHeader(BuildContext context, int group) {
    final g = widget.groups[group];
    final key = widget.groupKey(g);
    final status = _currentStatus(group, key);
    final state = _headerStates[key] ??= _createHeaderState(g, key, status);
    _builtStatuses[key] = status;
    return widget.headerBuilder(context, g, state, status);
  }

  S _createHeaderState(G group, Object key, StickyHeaderStatus status) {
    _applied[key] = status;
    return widget.createHeaderState(group, status, this);
  }

  /// Best known status: the last layout's, or a prediction from the group's
  /// position relative to the top group. Expansion is always current.
  StickyHeaderStatus _currentStatus(int group, Object key) {
    final expanded = widget.controller.isExpanded(key);
    final known = _statuses[key];
    if (known != null) return known.copyWith(isExpanded: expanded);
    final top = facts.topGroup;
    return StickyHeaderStatus(
      isExpanded: expanded,
      scrollPercentage: top != null && group < top ? 1 : 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Layout
  // ---------------------------------------------------------------------------

  @override
  void onRowsLaidOut(RenderSliverMultiBoxAdaptor list, double pixels) {
    _readRows(list, pixels);

    var statusChanged = false;
    final updates = <(G, S, StickyHeaderStatus)>[];
    for (final MapEntry(:key, value: state) in _headerStates.entries) {
      final group = _groupIndexByKey[key];
      if (group == null) continue;
      final status = _computeStatus(group, key);
      _statuses[key] = status;
      final built = _builtStatuses[key];
      if (built != null &&
          (built.isPinned != status.isPinned ||
              built.isExpanded != status.isExpanded)) {
        statusChanged = true;
      }
      if (_applied[key] != status) {
        _applied[key] = status;
        updates.add((widget.groups[group], state, status));
      }
    }
    if (updates.isNotEmpty) {
      // Updates may rebuild the headers (e.g. an animation jumping to its
      // end); a build scope lets that happen during layout, as it would in a
      // LayoutBuilder.
      final element = context as Element;
      element.owner!.buildScope(element, () {
        for (final (group, state, status) in updates) {
          widget.updateHeaderState(group, state, status);
        }
      });
    }

    if (statusChanged) {
      _scheduleRebuild();
    }
    _schedulePrune();
  }

  @override
  int get groupCount => widget.groups.length;

  @override
  void onPinnableGroups(Iterable<int> groups) => _pinnableGroups = {...groups};

  @override
  void onRowsRelaidOut(RenderSliverMultiBoxAdaptor list, double pixels) =>
      _readRows(list, pixels);

  void _readRows(RenderSliverMultiBoxAdaptor list, double pixels) {
    facts.capture(list, pixels);
    _measureRows();
    for (
      var row = facts.firstRow;
      row != null && row <= facts.lastRow!;
      row++
    ) {
      if (_rows.rowAt(row) case HeaderRow(:final group)) {
        _headerRowExtents[widget.groupKey(widget.groups[group])] = facts
            .extentOf(row)!;
      }
    }
    _locateTopGroup();
  }

  @override
  double shiftForResizedHeaders(Map<int, double> pinnableHeights) {
    _pinnableHeights
      ..clear()
      ..addAll(pinnableHeights);
    final first = facts.firstRow;
    final last = facts.lastRow;
    if (first == null || last == null) return 0;
    var shift = 0.0;
    for (final MapEntry(key: group, value: height) in pinnableHeights.entries) {
      if (group >= widget.groups.length) continue;
      final headerRow = _rows.headerRowOf(group);
      if (headerRow > last) continue;
      final key = widget.groupKey(widget.groups[group]);
      // Rows kept from the last layout are laid out again at their current
      // height (even if dropped afterwards); only rows dropped earlier need
      // the list moved for them.
      if (headerRow < first) {
        final previous = _headerRowExtents[key];
        if (previous != null) shift += height - previous;
      }
      _headerRowExtents[key] = height;
    }
    return shift;
  }

  void _locateTopGroup() {
    facts
      ..topGroup = null
      ..topGroupEnd = double.infinity
      ..pinnedGroup = null;
    final topRow = facts.rowAtPixels();
    if (topRow == null) return;

    final group = _rows.groupIndexAt(topRow);
    final end = _rows.endRowOf(group);
    facts
      ..topGroup = group
      ..topGroupEnd =
          facts.offsetOf(end) ?? facts.endOf(end - 1) ?? double.infinity;

    // Pinned while the group starts above the viewport and still reaches
    // into it. An unknown header offset means it's above the laid-out rows.
    final headerOffset = facts.offsetOf(_rows.headerRowOf(group));
    final startsAbove = headerOffset == null || facts.pixels > headerOffset;
    if (startsAbove && facts.topGroupEnd > facts.pixels) {
      facts.pinnedGroup = group;
    }
  }

  StickyHeaderStatus _computeStatus(int group, Object key) {
    final pinned = group == facts.pinnedGroup;
    final headerRow = _rows.headerRowOf(group);
    final headerOffset = facts.offsetOf(headerRow);
    final headerExtent =
        facts.extentOf(headerRow) ?? _pinnableHeights[group] ?? 0;

    final double position;
    if (pinned) {
      position = math.min(0.0, facts.topGroupEnd - facts.pixels - headerExtent);
    } else if (headerOffset != null) {
      position = -math.max(0.0, facts.pixels - headerOffset);
    } else {
      final top = facts.topGroup;
      position = top != null && group < top ? double.negativeInfinity : 0;
    }
    final ratio = headerExtent <= 0
        ? (position == 0 ? 0.0 : 1.0)
        : (position.abs() / headerExtent).clamp(0.0, 1.0);

    return StickyHeaderStatus(
      isPinned: pinned,
      isExpanded: widget.controller.isExpanded(key),
      scrollPercentage: ratio,
    );
  }

  void _scheduleRebuild() {
    if (_rebuildScheduled) return;
    _rebuildScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _rebuildScheduled = false;
      if (!mounted) return;
      // Header rows pick up the new statuses.
      setState(() {});
    });
  }

  /// Disposes header states whose header is no longer built. Runs after the
  /// frame so rows removed during layout have been unmounted first.
  void _schedulePrune() {
    if (_pruneScheduled) return;
    _pruneScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _pruneScheduled = false;
      if (mounted) _prune();
    });
  }

  void _prune() {
    final keep = <Object>{};
    final groups = widget.groups;
    final first = facts.firstRow;
    final last = facts.lastRow;
    if (first != null && last != null && last < _rows.length) {
      for (
        var g = _rows.groupIndexAt(first);
        g < groups.length && _rows.headerRowOf(g) <= last;
        g++
      ) {
        if (_rows.headerRowOf(g) >= first) keep.add(widget.groupKey(groups[g]));
      }
    }
    for (final g in _pinnableGroups) {
      if (g < groups.length) keep.add(widget.groupKey(groups[g]));
    }
    final stale = [
      for (final key in _headerStates.keys)
        if (!keep.contains(key)) key,
    ];
    for (final key in stale) {
      widget.disposeHeaderState(_headerStates.remove(key) as S);
      _applied.remove(key);
      _statuses.remove(key);
      _builtStatuses.remove(key);
      _headerRowExtents.remove(key);
    }
  }

  // ---------------------------------------------------------------------------
  // Controller commands
  // ---------------------------------------------------------------------------

  void _refreshHeaderStates() {
    for (final MapEntry(:key, value: state) in _headerStates.entries) {
      final group = _groupIndexByKey[key];
      if (group == null) continue;
      final status = _currentStatus(group, key);
      _applied[key] = status;
      widget.updateHeaderState(widget.groups[group], state, status);
    }
  }

  Future<bool> _revealItem(
    Object itemKey, {
    required double gap,
    required Duration duration,
    required Curve curve,
  }) async {
    final position = _itemPositions[itemKey];
    if (position == null) return false;
    final (group, item) = position;
    final row = _rows.rowOfItem(group, item);
    if (row == null) return false;

    final scroll = widget.scrollController.position;
    double targetFor(double rowOffset) =>
        (rowOffset - _headerExtentOf(group) - gap).clamp(
          scroll.minScrollExtent,
          scroll.maxScrollExtent,
        );

    // Not laid out yet: scroll to where it's estimated to be (only rows on
    // screen along the way are built), then correct once it's measured.
    var exact = true;
    if (facts.offsetOf(row) == null) {
      exact = false;
      final estimate = targetFor(_estimatedOffsetOfRow(row));
      if (duration == Duration.zero) {
        scroll.jumpTo(estimate);
      } else {
        await scroll.animateTo(estimate, duration: duration, curve: curve);
      }
      await SchedulerBinding.instance.endOfFrame;
      if (!mounted || facts.offsetOf(row) == null) return false;
    }

    final target = targetFor(facts.offsetOf(row)!);
    if ((target - scroll.pixels).abs() < 0.5) return true;
    if (!exact || duration == Duration.zero) {
      scroll.jumpTo(target);
    } else {
      await scroll.animateTo(target, duration: duration, curve: curve);
    }
    return true;
  }

  double _headerExtentOf(int group) =>
      facts.extentOf(_rows.headerRowOf(group)) ??
      _pinnableHeights[group] ??
      _headerRowExtents[widget.groupKey(widget.groups[group])] ??
      _averageExtent(header: true);

  // ---------------------------------------------------------------------------
  // Row estimates
  // ---------------------------------------------------------------------------

  Object _rowKey(int row) => switch (_rows.rowAt(row)) {
    HeaderRow(:final group) => (
      'header',
      widget.groupKey(widget.groups[group]),
    ),
    ItemRow(:final group, :final item) => (
      'item',
      widget.itemKey(widget.itemsOf(widget.groups[group])[item]),
    ),
  };

  double _estimatedExtentOf(int row) =>
      _measuredExtents[_rowKey(row)] ??
      _averageExtent(header: _rows.rowAt(row) is HeaderRow);

  double _averageExtent({required bool header}) {
    final (sum, count) = header ? _headerExtentSum : _itemExtentSum;
    if (count > 0) return sum / count;
    return math.max(facts.averageExtent, 1.0);
  }

  double _estimatedOffsetOfRow(int row) {
    var offset = 0.0;
    for (var r = 0; r < row; r++) {
      offset += _estimatedExtentOf(r);
    }
    return offset;
  }

  @override
  (int, double) estimateRowAt(double scrollOffset) {
    var offset = 0.0;
    for (var row = 0; row < _rows.length; row++) {
      final extent = _estimatedExtentOf(row);
      if (offset + extent > scrollOffset) return (row, offset);
      offset += extent;
    }
    final last = math.max(0, _rows.length - 1);
    return (last, math.max(0.0, offset - _estimatedExtentOf(last)));
  }

  void _measureRows() {
    final first = facts.firstRow;
    final last = facts.lastRow;
    if (first == null || last == null) return;
    for (var row = first; row <= last; row++) {
      final key = _rowKey(row);
      final extent = facts.extentOf(row)!;
      final isHeader = key is (String, Object) && key.$1 == 'header';
      final previous = _measuredExtents[key];
      _measuredExtents[key] = extent;
      if (isHeader) {
        _headerExtentSum = (
          _headerExtentSum.$1 - (previous ?? 0) + extent,
          _headerExtentSum.$2 + (previous == null ? 1 : 0),
        );
      } else {
        _itemExtentSum = (
          _itemExtentSum.$1 - (previous ?? 0) + extent,
          _itemExtentSum.$2 + (previous == null ? 1 : 0),
        );
      }
    }
  }
}
