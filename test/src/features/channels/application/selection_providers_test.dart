import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/cross_channel_search_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/selection_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/search_result_item.dart';
import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deleted_ids_providers.dart';
import 'package:youtube_takeout_manager/src/features/deletion/application/deletion_selection_controller.dart';
import 'package:youtube_takeout_manager/src/features/interactions/application/interaction_providers.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction_status.dart';
import 'package:youtube_takeout_manager/src/features/interactions/domain/queue_item_kind.dart';
import 'package:youtube_takeout_manager/src/features/live_chats/domain/live_chat.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';

class _Viewed extends Notifier<String?> {
  @override
  String? build() => 'UCa';

  void set(String channelId) => state = channelId;
}

final _viewed = NotifierProvider<_Viewed, String?>(_Viewed.new);

Comment _comment(String id) => Comment(
  commentId: id,
  channelId: 'UCme',
  createdAt: DateTime(2024),
  price: 0,
  rawCommentText: '{"text":"$id"}',
  displayText: id,
);

LiveChat _chat(String id) => LiveChat(
  liveChatId: id,
  channelId: 'UCme',
  createdAt: DateTime(2024),
  price: 0,
  rawText: '{"text":"$id"}',
  displayText: id,
);

void main() {
  ProviderContainer container({List<Interaction> searchResults = const []}) {
    final c = ProviderContainer(
      overrides: [
        viewedChannelIdProvider.overrideWith((ref) => ref.watch(_viewed)),
        channelInteractionsProvider(
          QueueItemKind.comment,
          'UCch',
        ).overrideWithValue([_comment('c1'), _comment('c2'), _comment('c3')]),
        channelInteractionsProvider(
          QueueItemKind.liveChat,
          'UCch',
        ).overrideWithValue([_chat('l1'), _chat('l2')]),
        crossChannelSearchItemsProvider.overrideWithValue([
          for (final item in searchResults)
            SearchResultItem(item, channelId: 'UCch'),
        ]),
        interactionStatusesProvider(QueueItemKind.comment).overrideWithValue(
          const InteractionStatuses(queued: {'c2'}, deleted: {'c3'}),
        ),
        interactionStatusesProvider(
          QueueItemKind.liveChat,
        ).overrideWithValue(const InteractionStatuses(failed: {'l2'})),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('selection mode', () {
    test('the channel list and each channel have their own', () {
      final c = container();
      c.listen(selectionModeProvider(), (_, _) {});
      c.listen(selectionModeProvider(channelId: 'UCa'), (_, _) {});
      c.listen(selectionModeProvider(channelId: 'UCb'), (_, _) {});

      c.read(selectionModeProvider(channelId: 'UCa').notifier).enter();

      expect(c.read(selectionModeProvider(channelId: 'UCa')), isTrue);
      expect(c.read(selectionModeProvider(channelId: 'UCb')), isFalse);
      expect(c.read(selectionModeProvider()), isFalse);
    });

    test('leaving it drops the selection', () {
      final c = container();
      c.listen(selectionModeProvider(channelId: 'UCa'), (_, _) {});
      c.listen(deletionSetProvider, (_, _) {});
      final mode = c.read(selectionModeProvider(channelId: 'UCa').notifier);
      mode.enter();
      c.read(deletionSetProvider.notifier).addAll({'c1', 'c2'});

      mode.exit();

      expect(c.read(selectionModeProvider(channelId: 'UCa')), isFalse);
      expect(c.read(deletionSetProvider), isEmpty);
    });

    test("a channel's screen starts out of it each time it opens", () async {
      final c = container();
      final screen = c.listen(
        selectionModeProvider(channelId: 'UCa'),
        (_, _) {},
      );
      c.read(selectionModeProvider(channelId: 'UCa').notifier).enter();

      screen.close();
      await c.pump();

      c.listen(selectionModeProvider(channelId: 'UCa'), (_, _) {});
      expect(c.read(selectionModeProvider(channelId: 'UCa')), isFalse);
    });

    test('the channel list leaves it when the search clears', () {
      final c = container();
      c.listen(channelSearchQueryProvider, (_, _) {});
      c.listen(selectionModeProvider(), (_, _) {});
      c.listen(selectionModeProvider(channelId: 'UCa'), (_, _) {});
      c.listen(deletionSetProvider, (_, _) {});
      c.read(channelSearchQueryProvider.notifier).update('hi');
      c.read(selectionModeProvider().notifier).enter();
      c.read(selectionModeProvider(channelId: 'UCa').notifier).enter();
      c.read(deletionSetProvider.notifier).addAll({'c1'});

      c.read(channelSearchQueryProvider.notifier).update('');

      expect(c.read(selectionModeProvider()), isFalse);
      expect(c.read(deletionSetProvider), isEmpty);
      // The channel list's search isn't a channel's.
      expect(c.read(selectionModeProvider(channelId: 'UCa')), isTrue);
    });

    test('the channel list leaves it when another channel is viewed', () {
      final c = container();
      c.listen(selectionModeProvider(), (_, _) {});
      c.read(selectionModeProvider().notifier).enter();

      c.read(_viewed.notifier).set('UCb');

      expect(c.read(selectionModeProvider()), isFalse);
    });
  });

  group("a channel's selection", () {
    test('counts and targets only its picked items', () {
      final c = container();
      c.listen(deletionSetProvider, (_, _) {});
      c.read(deletionSetProvider.notifier).addAll({'c1', 'l1', 'elsewhere'});

      final targets = c.read(selectedTargetsProvider(channelId: 'UCch'));

      expect(targets.count, 2);
      expect(targets.commentIds, {'c1'});
      expect(targets.liveChatIds, {'l1'});
    });

    test('can pick what is not deleted, queued or failed', () {
      final c = container();

      expect(c.read(selectableIdsProvider(channelId: 'UCch')), {'c1', 'l1'});
    });
  });

  group("the channel list's selection", () {
    test('counts and targets only the picked search results', () {
      final c = container(searchResults: [_comment('c1'), _chat('l1')]);
      c.listen(deletionSetProvider, (_, _) {});
      c.read(deletionSetProvider.notifier).addAll({'c1', 'c2'});

      final targets = c.read(selectedTargetsProvider());

      expect(targets.count, 1);
      expect(targets.commentIds, {'c1'});
    });

    test('can pick the search results not queued or failed', () {
      final c = container(
        searchResults: [
          _comment('c1'),
          _comment('c2'),
          _chat('l1'),
          _chat('l2'),
        ],
      );

      expect(c.read(selectableIdsProvider()), {'c1', 'l1'});
    });
  });
}
