import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:youtube_takeout_manager/src/features/categories/data/channel_category_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/storage/kv_storage_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ChannelCategoryRepository repository() =>
      ChannelCategoryRepository(KvStorageService());

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
    final saved = await KvStorageService().getString('channel_categories');
    await KvStorageService().setString(
      'channel_categories',
      saved!.replaceFirst('{', '{"UCbad":"nonsense",'),
    );

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
