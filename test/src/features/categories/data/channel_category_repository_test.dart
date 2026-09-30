import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/data/channel_category_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/storage/entry_store.dart';

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

  test("sub-categories AI made are kept by category", () async {
    await repository().saveCustomChildren({
      'Gaming': ['Speedruns'],
    });

    expect(await repository().loadCustomChildren(), {
      'Gaming': ['Speedruns'],
    });
  });
}
