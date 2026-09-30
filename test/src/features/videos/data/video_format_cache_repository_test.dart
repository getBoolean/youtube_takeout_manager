import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/videos/data/video_format_cache_repository.dart';
import 'package:youtube_takeout_manager/src/features/videos/domain/video_format.dart';
import 'package:youtube_takeout_manager/src/storage/entry_store.dart';

void main() {
  late Map<String, Map<String, String>> boxes;
  setUp(() => boxes = {});

  VideoFormatCacheRepository repository() =>
      VideoFormatCacheRepository(MemoryEntryStore(boxes));

  test('formats and videos YouTube lacks are kept and read back', () async {
    await repository().saveFormats({
      'a': const VideoFormat(seconds: 40, shape: VideoShape.tall),
      'b': const VideoFormat(seconds: 900),
    });
    await repository().saveNotFoundIds({'gone'});

    final formats = await repository().loadFormats();
    expect(
      {
        for (final e in formats.entries)
          e.key: (e.value.seconds, e.value.shape),
      },
      {'a': (40, VideoShape.tall), 'b': (900, null)},
    );
    expect(await repository().loadNotFoundIds(), {'gone'});
  });

  test('an entry that cannot be read is skipped, not the rest', () async {
    boxes[EntryBoxes.videoFormats] = {'a': '[40,2]', 'b': '"nonsense"'};

    expect((await repository().loadFormats()).keys, ['a']);
  });

  test('clearing forgets both', () async {
    await repository().saveFormats({'a': const VideoFormat(seconds: 40)});
    await repository().saveNotFoundIds({'gone'});

    await repository().clear();

    expect(await repository().loadFormats(), isEmpty);
    expect(await repository().loadNotFoundIds(), isEmpty);
  });
}
