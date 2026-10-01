import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/categorizing_channels.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categories.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categorizer.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/presentation/category_window.dart';
import 'package:youtube_takeout_manager/src/features/channels/application/channel_providers.dart';
import 'package:youtube_takeout_manager/src/features/channels/domain/channel_details.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import 'package:youtube_takeout_manager/src/theme/app_theme.dart';

const _gamer = HistoryChannel(channelId: 'UCg', title: 'Gamer');
final _decidedAt = DateTime.utc(2026, 9, 30);

/// Asks no AI: answers [suggestion] for any channel.
class _Categorizer extends ChannelCategorizer {
  _Categorizer({this.askable = true});

  final bool askable;

  @override
  void build() {}

  @override
  bool get canAskAi => askable;

  @override
  Future<ChannelCategory> suggest(HistoryChannel channel) async =>
      ChannelCategory(
        path: const CategoryPath('Gaming', 'Speedruns'),
        source: CategorySource.claude,
        tags: const ['Super Metroid'],
        tagsTried: true,
        decidedAt: _decidedAt,
      );
}

class _Details extends ChannelDetailsNotifier {
  _Details(this.topics);

  final List<String> topics;

  @override
  Future<Map<String, ChannelDetails>> build() async => {
    'UCg': ChannelDetails(topicUrls: topics),
  };
}

/// Opens Gamer's window, its category [category] (none when null).
Future<ProviderContainer> _open(
  WidgetTester tester, {
  ChannelCategory? category,
  List<String> topics = const [],
  bool signedIn = true,
  bool askable = true,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(800, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      channelCategorizerProvider.overrideWith(
        () => _Categorizer(askable: askable),
      ),
      channelDetailsProvider.overrideWith(() => _Details(topics)),
      readSessionChannelIdProvider.overrideWithValue(signedIn ? 'UCme' : null),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  if (category != null) {
    await container.read(channelCategoriesProvider.future);
    await container
        .read(channelCategoriesProvider.notifier)
        .decide('UCg', category);
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showCategoryWindow(context, channel: _gamer),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tapKey(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

String _topic(String slug) => 'https://en.wikipedia.org/wiki/$slug';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('Ask AI is offered', () {
    ChannelCategory category(CategorySource source, {CategoryPath? path}) =>
        ChannelCategory(path: path, source: source, decidedAt: _decidedAt);
    const action = CategoryPath('Gaming', 'Action');

    test("for YouTube's categories, Uncategorized and channels with none", () {
      for (final offered in [
        null,
        category(CategorySource.youtube, path: action),
        category(CategorySource.youtube),
        ChannelCategory(
          path: action,
          userDecision: UserDecision.accepted,
          decidedAt: _decidedAt,
        ),
      ]) {
        expect(
          askAiFor(offered, canAskAi: true, busy: false),
          AskAi.available,
          reason: '$offered',
        );
      }
    });

    test('not for a category AI or the user chose', () {
      for (final source in [
        CategorySource.jev,
        CategorySource.claude,
        CategorySource.user,
      ]) {
        expect(
          askAiFor(category(source, path: action), canAskAi: true, busy: false),
          AskAi.hidden,
          reason: '$source',
        );
      }
    });

    test('locked without a key, and waiting while the channel is asked '
        'about', () {
      expect(askAiFor(null, canAskAi: false, busy: false), AskAi.locked);
      expect(askAiFor(null, canAskAi: true, busy: true), AskAi.busy);
    });
  });

  testWidgets('a channel not categorized yet can be asked about', (
    tester,
  ) async {
    await _open(tester);

    expect(find.byKey(CategoryWindow.askAiKey), findsOneWidget);
    expect(
      tester
          .widget<ButtonStyleButton>(find.byKey(CategoryWindow.askAiKey))
          .enabled,
      isTrue,
    );
  });

  testWidgets('while categorizing asks AI about the channel, Ask AI waits', (
    tester,
  ) async {
    final container = await _open(tester);

    container.read(categorizingChannelsProvider.notifier).add('UCg');
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ButtonStyleButton>(find.byKey(CategoryWindow.askAiKey))
          .enabled,
      isFalse,
    );
    container.read(categorizingChannelsProvider.notifier).remove('UCg');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ButtonStyleButton>(find.byKey(CategoryWindow.askAiKey))
          .enabled,
      isTrue,
    );
  });

  group("YouTube's category", () {
    final claudes = ChannelCategory(
      path: const CategoryPath('Gaming', 'Speedruns'),
      source: CategorySource.claude,
      decidedAt: _decidedAt,
    );

    testWidgets('is offered when AI chose another, and using it makes it '
        "the user's choice", (tester) async {
      final container = await _open(
        tester,
        category: claudes,
        topics: [_topic('Action_game')],
      );

      expect(find.textContaining('Gaming › Action'), findsWidgets);
      await _tapKey(tester, CategoryWindow.useYouTubeKey);

      final kept = (await container.read(
        channelCategoriesProvider.future,
      ))['UCg'];
      expect(kept?.path, const CategoryPath('Gaming', 'Action'));
      expect(kept?.source, CategorySource.youtube);
      expect(kept?.userDecision, UserDecision.accepted);
    });

    testWidgets('is not offered when it is the same, or AI did not choose', (
      tester,
    ) async {
      await _open(
        tester,
        category: claudes.copyWith(
          path: const CategoryPath('Gaming', 'Action'),
        ),
        topics: [_topic('Action_game')],
      );
      expect(find.byKey(CategoryWindow.useYouTubeKey), findsNothing);
    });
  });

  testWidgets('signed out, with no topics, it says to sign in for them', (
    tester,
  ) async {
    await _open(
      tester,
      category: ChannelCategory(decidedAt: _decidedAt),
      signedIn: false,
    );

    expect(find.textContaining('Sign in'), findsOneWidget);
  });

  testWidgets("removing a tag makes the tags the user's", (tester) async {
    final container = await _open(
      tester,
      category: ChannelCategory(
        path: const CategoryPath('Gaming'),
        tags: const ['Mario Kart World', 'ASMR'],
        tagsTried: true,
        decidedAt: _decidedAt,
      ),
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(CategoryWindow.tagKey('ASMR')),
        matching: find.byTooltip('Remove ASMR'),
      ),
    );
    await tester.pumpAndSettle();

    final kept = (await container.read(
      channelCategoriesProvider.future,
    ))['UCg'];
    expect(kept?.tags, ['Mario Kart World']);
    expect(kept?.tagsEditedByUser, isTrue);
  });

  testWidgets("AI's suggestion is announced once it comes", (tester) async {
    final announced = <String>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      (message) async {
        if (message case {
          'type': 'announce',
          'data': {'message': final String text},
        }) {
          announced.add(text);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(
            SystemChannels.accessibility,
            null,
          ),
    );
    await _open(tester);

    await _tapKey(tester, CategoryWindow.askAiKey);

    expect(announced, hasLength(1));
    expect(announced.single, contains('Speedruns'));
  });
}
