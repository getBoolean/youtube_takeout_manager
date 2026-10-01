import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/data/channel_category_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/sub_category.dart';
import 'package:youtube_takeout_manager/src/storage/entry_store.dart';

/// Keeps entries in memory, recording the keys each write puts, and
/// failing the next write when [failNext].
class _Recording extends MemoryEntryStore {
  final puts = <String, List<String>>{};
  bool failNext = false;

  @override
  Future<void> putAll(String box, Map<String, String> entries) async {
    if (failNext) {
      failNext = false;
      throw StateError('write failed');
    }
    puts.putIfAbsent(box, () => []).addAll(entries.keys);
    return super.putAll(box, entries);
  }
}

void main() {
  late MemoryEntryStore store;
  setUp(() => store = MemoryEntryStore());

  ChannelCategoryRepository repository() => ChannelCategoryRepository(store);

  final category = ChannelCategory(
    path: const CategoryPath('Gaming', 'Speedruns'),
    source: CategorySource.claude,
    reason: 'Races through games',
    tried: const {CategorizationTier.youtube, CategorizationTier.claude},
    decidedAt: DateTime.utc(2026, 9, 30),
  );

  test('categories are kept and read back', () async {
    await repository().saveCategories({'UCa': category});

    expect(await repository().loadCategories(), {'UCa': category});
  });

  test('a category that cannot be read is skipped, not the rest', () async {
    await repository().saveCategories({'UCa': category});
    store.boxes[EntryBoxes.channelCategories]!['UCbad'] = '"nonsense"';

    expect((await repository().loadCategories()).keys, ['UCa']);
  });

  test('sub-categories are kept by category, with who made them and their '
      'emoji', () async {
    final custom = {
      'Gaming': [
        const SubCategory(name: 'Speedruns'),
        const SubCategory(name: 'Retro', origin: NameOrigin.user, emoji: '👾'),
      ],
    };

    await repository().saveCustomChildren(custom);

    expect(await repository().loadCustomChildren(), custom);
  });

  test('sub-categories kept as names alone read as made by AI', () async {
    store.boxes[EntryBoxes.customSubCategories] = {'Gaming': '["Speedruns"]'};

    expect(await repository().loadCustomChildren(), {
      'Gaming': [const SubCategory(name: 'Speedruns')],
    });
  });

  group('names that differ only by hyphens, spaces or case', () {
    ChannelCategory claude(String child) => ChannelCategory(
      path: CategoryPath('Gaming', child),
      source: CategorySource.claude,
      decidedAt: DateTime.utc(2026, 9, 30),
    );

    /// A store holding Speedruns twice over, and a channel of each.
    Future<_Recording> stored() async {
      final recording = _Recording();
      final before = ChannelCategoryRepository(recording);
      await before.saveCategories({
        'UCa': claude('Speedruns'),
        'UCb': claude('Speedruns'),
        'UCc': claude('Speed-runs'),
        'UCd': ChannelCategory(
          path: const CategoryPath('Music', 'Pop'),
          decidedAt: DateTime.utc(2026, 9, 30),
        ),
      });
      await before.saveCustomChildren({
        'Gaming': [
          const SubCategory(name: 'Speed-runs'),
          const SubCategory(name: 'Speedruns'),
        ],
        'Music': [const SubCategory(name: 'Shoegaze')],
      });
      recording.puts.clear();
      return recording;
    }

    test(
      'are merged on the first load, writing back only what changed',
      () async {
        final recording = await stored();
        final repository = ChannelCategoryRepository(recording);

        final categories = await repository.loadCategories();
        final custom = await repository.loadCustomChildren();

        expect(
          categories['UCc']?.path,
          const CategoryPath('Gaming', 'Speedruns'),
        );
        expect(subCategoryNames(custom), {
          'Gaming': ['Speedruns'],
          'Music': ['Shoegaze'],
        });
        expect(recording.puts, {
          EntryBoxes.channelCategories: ['UCc'],
          EntryBoxes.customSubCategories: ['Gaming'],
        });
        expect(
          (await ChannelCategoryRepository(
            recording,
          ).loadCategories())['UCc']?.path,
          const CategoryPath('Gaming', 'Speedruns'),
        );
      },
    );

    test('merged once, write nothing on the next launch', () async {
      final recording = await stored();
      final first = ChannelCategoryRepository(recording);
      await first.loadCategories();
      await first.loadCustomChildren();
      recording.puts.clear();

      final next = ChannelCategoryRepository(recording);
      await next.loadCategories();
      await next.loadCustomChildren();

      expect(recording.puts, isEmpty);
    });

    test('still load merged when writing them back fails, and are merged '
        'again on the next launch', () async {
      final recording = await stored();
      recording.failNext = true;

      final categories = await ChannelCategoryRepository(
        recording,
      ).loadCategories();
      expect(
        categories['UCc']?.path,
        const CategoryPath('Gaming', 'Speedruns'),
      );

      final next = await ChannelCategoryRepository(recording).loadCategories();
      expect(next['UCc']?.path, const CategoryPath('Gaming', 'Speedruns'));
      expect(recording.puts[EntryBoxes.channelCategories], ['UCc']);
    });
  });
}
