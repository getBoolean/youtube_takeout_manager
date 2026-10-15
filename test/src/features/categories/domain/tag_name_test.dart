import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/name_key.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/sub_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/tag_name.dart';

void main() {
  group('tags named, merged into the tags there are', () {
    test('a new one is kept, tidied, with its meaning, as made by whoever '
        'named it', () {
      final merged = mergeNamedTags(const {}, [
        (name: ' Phase  Connect ', meaning: ' A VTuber agency '),
      ], NameOrigin.ai);

      expect(merged.resolved, ['Phase Connect']);
      final tag = merged.names[nameKey('Phase Connect')]!;
      expect(tag.name, 'Phase Connect');
      expect(tag.meaning, 'A VTuber agency');
      expect(tag.origin, NameOrigin.ai);
    });

    test('a known one is spelled as it is, and an AI tag with no meaning '
        "takes the one AI gives", () {
      final names = {nameKey('VTuber'): const TagName(name: 'VTuber')};

      final merged = mergeNamedTags(names, [
        (name: 'vtuber', meaning: 'A streamer shown as an avatar'),
      ], NameOrigin.ai);

      expect(merged.resolved, ['VTuber']);
      expect(
        merged.names[nameKey('VTuber')]!.meaning,
        'A streamer shown as an avatar',
      );
    });

    test('a meaning is never replaced', () {
      final names = {
        nameKey('ASMR'): const TagName(name: 'ASMR', meaning: 'Soft sounds'),
      };

      final merged = mergeNamedTags(names, [
        (name: 'ASMR', meaning: 'Whispering'),
      ], NameOrigin.ai);

      expect(merged.names[nameKey('ASMR')]!.meaning, 'Soft sounds');
      expect(identical(merged.names, names), isTrue);
    });

    test("the user's tags take no meaning from AI", () {
      final names = {
        nameKey('Hololive'): const TagName(
          name: 'Hololive',
          origin: NameOrigin.user,
        ),
      };

      final merged = mergeNamedTags(names, [
        (name: 'Hololive', meaning: 'A VTuber agency'),
      ], NameOrigin.ai);

      expect(merged.resolved, ['Hololive']);
      expect(merged.names[nameKey('Hololive')]!.meaning, isNull);
    });

    test('a deleted one is left out, and stays deleted', () {
      final names = {
        nameKey('Streaming'): const TagName(name: 'Streaming', deleted: true),
      };

      final merged = mergeNamedTags(names, [
        (name: 'Streaming', meaning: 'Live streams'),
        (name: 'Music', meaning: 'Songs'),
      ], NameOrigin.ai);

      expect(merged.resolved, ['Music']);
      expect(merged.names[nameKey('Streaming')]!.deleted, isTrue);
      expect(merged.names[nameKey('Streaming')]!.meaning, isNull);
    });

    test('each comes once, blanks left out, at most 5', () {
      final merged = mergeNamedTags(const {}, [
        for (final name in ['A', 'a', ' ', 'B', 'C', 'D', 'E', 'F'])
          (name: name, meaning: null),
      ], NameOrigin.user);

      expect(merged.resolved, ['A', 'B', 'C', 'D', 'E']);
      expect(merged.names.containsKey(nameKey('F')), isFalse);
    });
  });
}
