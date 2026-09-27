import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/selection_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/presentation/selection_bars.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_selection_controller.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';

Comment _comment(String id) => Comment(
  commentId: id,
  channelId: 'UCme',
  createdAt: DateTime(2024),
  price: 0,
  rawCommentText: '{"text":"$id"}',
  displayText: id,
);

void main() {
  Future<ProviderContainer> pumpBar(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        viewedChannelIdProvider.overrideWithValue('UCme'),
        selectionCandidatesProvider(
          channelId: 'UCch',
        ).overrideWithValue([_comment('c1'), _comment('c2')]),
        selectableIdsProvider(
          channelId: 'UCch',
        ).overrideWithValue({'c1', 'c2'}),
      ],
    );
    addTearDown(container.dispose);
    // Kept by the screen's other widgets in the app.
    container.listen(deletionSetProvider, (_, _) {});
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            appBar: SelectionAppBar(
              channelId: 'UCch',
              title: Text('A channel'),
            ),
          ),
        ),
      ),
    );
    return container;
  }

  testWidgets('shows its title until selection mode, then the count', (
    tester,
  ) async {
    final container = await pumpBar(tester);
    expect(find.text('A channel'), findsOneWidget);

    container.read(selectionModeProvider(channelId: 'UCch').notifier).enter();
    container.read(deletionSetProvider.notifier).addAll({'c1', 'elsewhere'});
    await tester.pump();

    expect(find.text('A channel'), findsNothing);
    expect(find.text('1 selected'), findsOneWidget);
  });

  testWidgets('closing leaves selection mode and drops the selection', (
    tester,
  ) async {
    final container = await pumpBar(tester);
    container.read(selectionModeProvider(channelId: 'UCch').notifier).enter();
    container.read(deletionSetProvider.notifier).addAll({'c1'});
    await tester.pump();

    await tester.tap(find.byType(CloseButton));
    await tester.pump();

    expect(container.read(selectionModeProvider(channelId: 'UCch')), isFalse);
    expect(container.read(deletionSetProvider), isEmpty);
    expect(find.text('A channel'), findsOneWidget);
  });
}
