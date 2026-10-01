import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/authentication/application/read_session.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categories.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_categorizer.dart';
import 'package:youtube_takeout_manager/src/features/categories/application/channel_tags.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/sub_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/presentation/category_tag_page.dart';
import 'package:youtube_takeout_manager/src/features/categories/presentation/category_window.dart';
import 'package:youtube_takeout_manager/src/features/history/domain/watched_channels.dart';
import 'package:youtube_takeout_manager/src/theme/app_theme.dart';

const _gamer = HistoryChannel(channelId: 'UCg', title: 'Gamer');

class _Categorizer extends ChannelCategorizer {
  @override
  void build() {}

  @override
  bool get canAskAi => false;
}

const List<TagUse> _usage = [
  (name: 'ASMR', channels: 4, origin: NameOrigin.ai),
  (name: 'Mario Kart World', channels: 2, origin: NameOrigin.ai),
  (name: 'Jazz piano', channels: 1, origin: NameOrigin.user),
];

ChannelCategory _tagged(List<String> tags) => ChannelCategory(
  path: const CategoryPath('Gaming'),
  tags: tags,
  tagsTried: true,
  decidedAt: DateTime.utc(2026, 10, 1),
);

/// Opens Gamer's window at Add tag, other channels having [others]' tags.
Future<ProviderContainer> _open(
  WidgetTester tester, {
  Map<String, List<String>> others = const {},
}) async {
  tester.view.physicalSize = const Size(800, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [
      channelCategorizerProvider.overrideWith(_Categorizer.new),
      readSessionChannelIdProvider.overrideWithValue(null),
    ],
  );
  addTearDown(container.dispose);
  await container.read(channelCategoriesProvider.future);
  await container.read(tagNamesProvider.notifier).resolve([
    for (final tags in others.values) ...tags,
  ], NameOrigin.ai);
  await container.read(channelCategoriesProvider.notifier).replaceAll({
    'UCg': _tagged(const ['Speedruns']),
    for (final MapEntry(:key, :value) in others.entries) key: _tagged(value),
  });
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
  await tester.tap(find.byKey(CategoryWindow.addTagKey));
  await tester.pumpAndSettle();
  return container;
}

Future<List<String>> _tags(ProviderContainer c) async =>
    (await c.read(channelCategoriesProvider.future))['UCg']?.tags ?? const [];

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('the tags offered', () {
    test(
      'are the ones in use, the most used first, but not the channel\'s',
      () {
        expect(
          [
            for (final row in tagRows(_usage, has: const ['ASMR'])) row.name,
          ],
          ['Mario Kart World', 'Jazz piano'],
        );
      },
    );

    test('narrow to the text typed, whatever its case or accents', () {
      expect(
        [
          for (final row in tagRows(_usage, has: const [], text: 'mario'))
            row.name,
        ],
        ['mario', 'Mario Kart World'],
      );
    });

    test('start with the text typed, as a new tag, unless one folds the '
        'same', () {
      final rows = tagRows(_usage, has: const [], text: 'Retro');
      expect(rows.first.isNew, isTrue);
      expect(rows.first.name, 'Retro');

      expect(
        tagRows(_usage, has: const [], text: 'asmr').any((row) => row.isNew),
        isFalse,
      );
    });

    test('mark the ones AI made', () {
      final rows = tagRows(_usage, has: const []);
      expect(
        {for (final row in rows) row.name: row.aiMade},
        {'ASMR': true, 'Mario Kart World': true, 'Jazz piano': false},
      );
    });
  });

  testWidgets('typing narrows the tags offered', (tester) async {
    await _open(
      tester,
      others: {
        'UCa': ['ASMR'],
        'UCb': ['Mario Kart World'],
      },
    );
    expect(find.byKey(AddTagPage.rowKey('ASMR')), findsOneWidget);

    await tester.enterText(find.byKey(AddTagPage.fieldKey), 'kart');
    await tester.pumpAndSettle();

    expect(find.byKey(AddTagPage.rowKey('ASMR')), findsNothing);
    expect(find.byKey(AddTagPage.rowKey('Mario Kart World')), findsOneWidget);
  });

  testWidgets('picking a tag AI made adds it as AI spelled it, still '
      'AI-made', (tester) async {
    final container = await _open(
      tester,
      others: {
        'UCa': ['Mario Kart World'],
      },
    );

    await tester.enterText(find.byKey(AddTagPage.fieldKey), 'mario-kart');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AddTagPage.rowKey('Mario Kart World')));
    await tester.pumpAndSettle();

    expect(await _tags(container), ['Speedruns', 'Mario Kart World']);
    final names = await container.read(tagNamesProvider.future);
    expect(
      names.values.where((t) => t.name == 'Mario Kart World').single.origin,
      NameOrigin.ai,
    );
    expect(find.byKey(CategoryWindow.changeKey), findsOneWidget);
  });

  testWidgets('a new tag typed in is the user\'s', (tester) async {
    final container = await _open(tester);

    await tester.enterText(find.byKey(AddTagPage.fieldKey), 'Retro');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AddTagPage.newKey));
    await tester.pumpAndSettle();

    expect(await _tags(container), ['Speedruns', 'Retro']);
    final kept = (await container.read(
      channelCategoriesProvider.future,
    ))['UCg'];
    expect(kept?.tagsEditedByUser, isTrue);
    final names = await container.read(tagNamesProvider.future);
    expect(
      names.values.where((t) => t.name == 'Retro').single.origin,
      NameOrigin.user,
    );
  });
}
