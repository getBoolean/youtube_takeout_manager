/// Flat row layout of a grouped list: every group contributes a header row
/// followed by its item rows when expanded.
///
/// Built in O(groups); lookups by row are O(log groups).
class GroupRows {
  GroupRows(List<int> itemCounts, bool Function(int group) isExpanded)
    : _starts = List<int>.filled(itemCounts.length + 1, 0) {
    var row = 0;
    for (var g = 0; g < itemCounts.length; g++) {
      _starts[g] = row;
      row += 1 + (isExpanded(g) ? itemCounts[g] : 0);
    }
    _starts[itemCounts.length] = row;
  }

  /// `_starts[g]` is the header row of group `g`; the last entry is [length].
  final List<int> _starts;

  int get length => _starts.last;

  int get groupCount => _starts.length - 1;

  int headerRowOf(int group) => _starts[group];

  /// One past the group's last row.
  int endRowOf(int group) => _starts[group + 1];

  int shownItemCount(int group) => _starts[group + 1] - _starts[group] - 1;

  int groupIndexAt(int row) {
    assert(row >= 0 && row < length, 'row $row out of range 0..$length');
    var low = 0;
    var high = groupCount - 1;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (_starts[mid] <= row) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  GroupRow rowAt(int row) {
    final group = groupIndexAt(row);
    final offset = row - _starts[group];
    return offset == 0 ? HeaderRow(group) : ItemRow(group, offset - 1);
  }

  /// The row of the group's [item], or null while the group is collapsed.
  int? rowOfItem(int group, int item) =>
      item < shownItemCount(group) ? _starts[group] + 1 + item : null;
}

sealed class GroupRow {
  const GroupRow(this.group);

  final int group;
}

final class HeaderRow extends GroupRow {
  const HeaderRow(super.group);

  @override
  bool operator ==(Object other) => other is HeaderRow && other.group == group;

  @override
  int get hashCode => Object.hash(HeaderRow, group);

  @override
  String toString() => 'HeaderRow($group)';
}

final class ItemRow extends GroupRow {
  const ItemRow(super.group, this.item);

  final int item;

  @override
  bool operator ==(Object other) =>
      other is ItemRow && other.group == group && other.item == item;

  @override
  int get hashCode => Object.hash(ItemRow, group, item);

  @override
  String toString() => 'ItemRow($group, $item)';
}
