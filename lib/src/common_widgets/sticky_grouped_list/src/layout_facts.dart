part of '../sticky_grouped_list.dart';

/// What the list's last layout produced: the laid-out rows' scroll offsets
/// and extents, and which group is at the top.
class _LayoutFacts {
  double pixels = 0;

  /// Laid-out rows are contiguous, starting at [firstRow].
  int? firstRow;
  final List<double> _offsets = [];
  final List<double> _extents = [];

  /// Group containing the row at the top of the viewport.
  int? topGroup;

  /// Scroll offset where [topGroup] ends, or infinity when unknown (beyond
  /// the laid-out rows).
  double topGroupEnd = double.infinity;

  int? pinnedGroup;

  /// The in-list header row hidden because its pinned copy is shown.
  int? hiddenHeaderGroup;
  final Set<_RenderHeaderRowSlot> headerRowSlots = {};

  bool get isEmpty => firstRow == null;

  int? get lastRow => firstRow == null ? null : firstRow! + _offsets.length - 1;

  void capture(RenderSliverMultiBoxAdaptor list, double pixels) {
    this.pixels = pixels;
    firstRow = null;
    _offsets.clear();
    _extents.clear();
    var child = list.firstChild;
    while (child != null) {
      final index = list.indexOf(child);
      firstRow ??= index;
      assert(index == firstRow! + _offsets.length, 'rows must be contiguous');
      _offsets.add(list.childScrollOffset(child)!);
      _extents.add(child.size.height);
      child = list.childAfter(child);
    }
  }

  double? offsetOf(int row) {
    final i = _indexOf(row);
    return i == null ? null : _offsets[i];
  }

  double? extentOf(int row) {
    final i = _indexOf(row);
    return i == null ? null : _extents[i];
  }

  double? endOf(int row) {
    final i = _indexOf(row);
    return i == null ? null : _offsets[i] + _extents[i];
  }

  /// First laid-out row still visible at [pixels], or the last row when all
  /// are above it.
  int? rowAtPixels() {
    if (firstRow == null) return null;
    for (var i = 0; i < _offsets.length; i++) {
      if (_offsets[i] + _extents[i] > pixels) return firstRow! + i;
    }
    return lastRow;
  }

  double get averageExtent {
    if (_extents.isEmpty) return 0;
    return _extents.reduce((a, b) => a + b) / _extents.length;
  }

  int? _indexOf(int row) {
    final first = firstRow;
    if (first == null) return null;
    final i = row - first;
    return i >= 0 && i < _offsets.length ? i : null;
  }
}
