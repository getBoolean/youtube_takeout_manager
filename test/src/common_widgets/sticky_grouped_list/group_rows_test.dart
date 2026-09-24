import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/common_widgets/sticky_grouped_list/src/group_rows.dart';

void main() {
  group('GroupRows', () {
    test('is empty without groups', () {
      final rows = GroupRows(const [], (_) => true);
      expect(rows.length, 0);
      expect(rows.groupCount, 0);
    });

    test('lays out a header then the items of each expanded group', () {
      final rows = GroupRows(const [2, 0, 3], (_) => true);
      expect(rows.length, 3 + 5);
      expect(
        [for (var r = 0; r < rows.length; r++) rows.rowAt(r)],
        const [
          HeaderRow(0),
          ItemRow(0, 0),
          ItemRow(0, 1),
          HeaderRow(1),
          HeaderRow(2),
          ItemRow(2, 0),
          ItemRow(2, 1),
          ItemRow(2, 2),
        ],
      );
      expect(rows.headerRowOf(2), 4);
      expect(rows.endRowOf(2), 8);
      expect(rows.rowOfItem(2, 1), 6);
    });

    test('collapsed groups keep only their header', () {
      final rows = GroupRows(const [2, 3, 1], (g) => g != 1);
      expect(rows.length, 3 + 2 + 1);
      expect(rows.rowAt(3), const HeaderRow(1));
      expect(rows.rowAt(4), const HeaderRow(2));
      expect(rows.shownItemCount(1), 0);
      expect(rows.rowOfItem(1, 0), isNull);
      expect(rows.rowOfItem(2, 0), 5);
    });

    test('groupIndexAt finds the group at its first and last rows', () {
      final rows = GroupRows(const [3, 1, 4], (_) => true);
      expect(rows.groupIndexAt(0), 0);
      expect(rows.groupIndexAt(3), 0);
      expect(rows.groupIndexAt(4), 1);
      expect(rows.groupIndexAt(5), 1);
      expect(rows.groupIndexAt(6), 2);
      expect(rows.groupIndexAt(rows.length - 1), 2);
    });

    test('rowOfItem is null past the group end', () {
      final rows = GroupRows(const [2], (_) => true);
      expect(rows.rowOfItem(0, 2), isNull);
    });
  });
}
