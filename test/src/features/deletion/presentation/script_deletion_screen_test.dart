import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_queue_notifier.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_service.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/script_deletion_ids.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/script_generator_service.dart';
import 'package:youtube_takeout_manager/src/features/deletion/data/deletion_queue_repository.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_item_status.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_queue_item.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/deletion_targets.dart';
import 'package:youtube_takeout_manager/src/features/deletion/domain/my_activity_results.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/script_deletion_screen.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';
import 'package:youtube_takeout_manager/src/features/takeout/domain/takeout_data.dart';

class _FakeGenerator extends ScriptGeneratorService {
  final requested = <Set<String>>[];

  @override
  Future<String> generateDeletionScript(Set<String> ids) async {
    requested.add(ids);
    return 'the script';
  }
}

LiveChat _chat(String id, String text) => LiveChat(
  liveChatId: id,
  channelId: 'UCme',
  createdAt: DateTime.utc(2026),
  price: 0,
  rawText: text,
  displayText: text,
);

DeletionQueueItem _item(String itemId, QueueItemKind kind) => DeletionQueueItem(
  id: 'q-$itemId',
  itemId: itemId,
  itemType: kind,
  status: DeletionItemStatus.pending,
  createdAt: DateTime.utc(2026),
  authorChannelId: 'UCme',
);

/// Fails to save results, as when storage can't be written.
class _FailingService extends DeletionService {
  @override
  Future<void> recordMyActivityResults(
    DeletionTargets targets,
    MyActivityResults results,
  ) => Future.error(StateError('disk full'));
}

const _targets = DeletionTargets(
  commentSnippets: {'c1': 'hi'},
  liveChatSnippets: {'l1': '', 'l2': 'yo'},
);

void main() {
  late ProviderContainer container;
  late _FakeGenerator generator;

  Future<void> pumpScreen(
    WidgetTester tester, {
    List<Override> overrides = const [],
  }) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    generator = _FakeGenerator();
    container = ProviderContainer(
      overrides: [
        viewedChannelIdProvider.overrideWithValue('UCme'),
        viewedTakeoutProvider.overrideWithValue(
          AsyncData(
            TakeoutData(
              comments: const [],
              liveChats: [_chat('l1', ' '), _chat('l2', 'yo')],
              subscriptionsByChannelId: const {},
            ),
          ),
        ),
        scriptGeneratorServiceProvider.overrideWithValue(generator),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      await container.read(deletionQueueRepositoryProvider).saveQueue([
        _item('c1', QueueItemKind.comment),
        _item('l1', QueueItemKind.liveChat),
        _item('l2', QueueItemKind.liveChat),
      ]);
      await container.read(deletionQueueProvider.future);
      await container.read(deletedIdsProvider.future);
    });
    container.read(scriptDeletionIdsProvider.notifier).set(_targets);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ScriptDeletionScreen()),
      ),
    );
  }

  Future<void> goToImport(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next').hitTestable());
      await tester.pumpAndSettle();
    }
  }

  Future<void> importResults(WidgetTester tester, String json) async {
    await tester.enterText(find.byType(TextField).hitTestable(), json);
    await tester.runAsync(() async {
      await tester.tap(find.text('Import Results').hitTestable().last);
      // Lets the results save.
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
  }

  testWidgets("warns about live chats with no text in the takeout", (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(
      find.text(
        '1 item may be a membership event or already-deleted message. '
        'Deletion may fail for it.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('copies a script for every item', (tester) async {
    await pumpScreen(tester);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.tap(find.text('Next').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('This script will delete 3 items.'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.copy));
    await tester.pumpAndSettle();

    expect(generator.requested.single, {'c1', 'l1', 'l2'});
    expect(copied, 'the script');
    expect(find.text('Copied!'), findsOneWidget);
  });

  testWidgets('importing results records them, and retrying keeps only the '
      'failed ones', (tester) async {
    await pumpScreen(tester);
    await goToImport(tester);

    await importResults(
      tester,
      '{"succeeded":["c1","l2"],"failed":[{"id":"l1","error":"Not found"}]}',
    );

    expect(find.text('2 deleted'), findsOneWidget);
    expect(find.text('1 failed'), findsOneWidget);
    expect(find.text('l1: Not found'), findsOneWidget);
    final deleted = container.read(deletedIdsProvider).requireValue;
    expect(deleted[QueueItemKind.comment], {'c1'});
    expect(deleted[QueueItemKind.liveChat], {'l2'});
    final statuses = {
      for (final i in container.read(deletionQueueProvider).requireValue)
        i.itemId: i.status,
    };
    expect(statuses, {
      'c1': DeletionItemStatus.succeeded,
      'l1': DeletionItemStatus.failed,
      'l2': DeletionItemStatus.succeeded,
    });

    await tester.tap(find.text('Retry Failed').hitTestable());
    await tester.pumpAndSettle();

    expect(container.read(scriptDeletionIdsProvider).liveChatIds, {'l1'});
    expect(container.read(scriptDeletionIdsProvider).commentIds, isEmpty);
    expect(find.text('This script will delete 1 item.'), findsOneWidget);
  });

  testWidgets('pasting something else says so and records nothing', (
    tester,
  ) async {
    await pumpScreen(tester);
    await goToImport(tester);

    await importResults(tester, 'not json');

    expect(
      find.textContaining('Invalid JSON: FormatException'),
      findsOneWidget,
    );
    expect(find.text('Import Results'), findsWidgets);
    expect(
      container.read(deletedIdsProvider).requireValue[QueueItemKind.comment],
      isEmpty,
    );
  });

  testWidgets('says so when the results can’t be saved', (tester) async {
    await pumpScreen(
      tester,
      overrides: [deletionServiceProvider.overrideWith(_FailingService.new)],
    );
    await goToImport(tester);

    await importResults(tester, '{"succeeded":["c1"],"failed":[]}');

    expect(
      find.text("Couldn't save the results: Bad state: disk full"),
      findsOneWidget,
    );
    // Still on the paste step, to try again.
    expect(find.text('1 deleted'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });
}
