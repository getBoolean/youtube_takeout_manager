import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction_status.dart';
import 'package:youtube_takeout_manager/src/features/interactions/presentation/interaction_tile.dart';

Future<void> _pumpTile(
  WidgetTester tester,
  InteractionStatus status, {
  bool dimUnselectable = false,
}) => tester.pumpWidget(
  MaterialApp(
    home: Material(
      child: InteractionTile(
        status: status,
        icon: Icons.comment_outlined,
        iconColor: Colors.blue,
        title: const Text('title'),
        subtitle: const Text('subtitle'),
        isSelected: false,
        selectionMode: false,
        dimUnselectable: dimUnselectable,
        onTap: () {},
        onLongPress: null,
      ),
    ),
  ),
);

double _opacity(WidgetTester tester) =>
    tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

void main() {
  testWidgets('only deleted items are dimmed by default', (tester) async {
    for (final (status, opacity) in [
      (InteractionStatus.deleted, 0.5),
      (InteractionStatus.failed, 1.0),
      (InteractionStatus.queued, 1.0),
      (InteractionStatus.active, 1.0),
    ]) {
      await _pumpTile(tester, status);
      expect(_opacity(tester), opacity, reason: status.name);
    }
  });

  testWidgets('dimUnselectable also dims queued and failed items', (
    tester,
  ) async {
    for (final (status, opacity) in [
      (InteractionStatus.deleted, 0.5),
      (InteractionStatus.failed, 0.5),
      (InteractionStatus.queued, 0.5),
      (InteractionStatus.active, 1.0),
    ]) {
      await _pumpTile(tester, status, dimUnselectable: true);
      expect(_opacity(tester), opacity, reason: status.name);
    }
  });

  testWidgets("the status icon replaces the item's own icon", (tester) async {
    await _pumpTile(tester, InteractionStatus.queued);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
    expect(find.byIcon(Icons.comment_outlined), findsNothing);

    await _pumpTile(tester, InteractionStatus.active);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.comment_outlined), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsNothing);
  });
}
