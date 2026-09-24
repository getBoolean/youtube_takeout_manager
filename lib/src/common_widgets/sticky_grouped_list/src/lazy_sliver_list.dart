part of '../sticky_grouped_list.dart';

/// Estimates where rows sit from the extents measured so far.
abstract interface class _RowEstimator {
  /// The row at [scrollOffset] and that row's estimated leading edge.
  (int row, double offset) estimateRowAt(double scrollOffset);
}

/// A [SliverList] that jumps instead of walking: when asked to lay out far
/// from its current rows (a scrollbar drag, a long fling, a programmatic
/// jump), it drops them and restarts at the estimated row rather than
/// building every row in between.
///
/// Estimates are corrected as rows are measured; any remaining error is
/// reconciled by [RenderSliverList]'s own scroll offset correction when the
/// user scrolls back to the start.
class _LazySliverList extends SliverMultiBoxAdaptorWidget {
  const _LazySliverList({required super.delegate, required this.estimator});

  final _RowEstimator estimator;

  @override
  SliverMultiBoxAdaptorElement createElement() =>
      SliverMultiBoxAdaptorElement(this, replaceMovedChildren: true);

  @override
  _RenderLazySliverList createRenderObject(BuildContext context) =>
      _RenderLazySliverList(
        childManager: context as SliverMultiBoxAdaptorElement,
        estimator: estimator,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLazySliverList renderObject,
  ) {
    renderObject.estimator = estimator;
  }
}

class _RenderLazySliverList extends RenderSliverList {
  _RenderLazySliverList({required super.childManager, required this.estimator});

  _RowEstimator estimator;

  @override
  void performLayout() {
    final first = firstChild;
    final last = lastChild;
    // Rows inserted since the last layout have no offset or size yet.
    final laidOutStart = first == null ? null : childScrollOffset(first);
    final lastStart = last == null ? null : childScrollOffset(last);
    if (last != null &&
        last.hasSize &&
        laidOutStart != null &&
        lastStart != null) {
      final laidOutEnd = lastStart + paintExtentOf(last);
      final from = constraints.scrollOffset + constraints.cacheOrigin;
      final to = from + constraints.remainingCacheExtent;
      // More than a screen away from anything laid out: start over there.
      final gap = constraints.viewportMainAxisExtent;
      if (from > laidOutEnd + gap || to < laidOutStart - gap) {
        final (row, offset) = estimator.estimateRowAt(constraints.scrollOffset);
        collectGarbage(childCount, 0);
        addInitialChild(index: row, layoutOffset: offset);
      }
    }
    super.performLayout();
  }
}
