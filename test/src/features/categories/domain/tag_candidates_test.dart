import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/category_path.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/channel_evidence.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/name_key.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/sub_category.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/tag_candidates.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/tag_name.dart';

const _gaming = CategoryPath('Gaming');
const _music = CategoryPath('Music');

/// The registry for [names], AI-named, by key.
Map<String, TagName> _ai(Iterable<String> names) => {
  for (final name in names) nameKey(name): TagName(name: name),
};

/// Channels in [path], one per tag of [tags] repeated [times] times, so
/// each tag is used that often there.
Map<String, ChannelCategory> _using(
  Map<String, int> tags, {
  CategoryPath path = _gaming,
  String prefix = 'UC',
}) => {
  for (final MapEntry(key: tag, value: times) in tags.entries)
    for (var i = 0; i < times; i++)
      '$prefix-$tag-$i': ChannelCategory(
        path: path,
        tags: [tag],
        tagsTried: true,
        decidedAt: DateTime.utc(2026, 10, 1),
      ),
};

ChannelEvidence _evidence({
  String title = 'Some channel',
  String? description,
  List<String> titles = const [],
}) => ChannelEvidence(title: title, description: description, titles: titles);

List<String> _names(List<TagCandidate> candidates) => [
  for (final c in candidates) c.tag.name,
];

void main() {
  group("a channel's candidate tags", () {
    final many = {for (var i = 0; i < 70; i++) 'Common $i': 100 - i};

    test("are all the user's tags that have a meaning, first, past the "
        '60 from AI', () {
      final names = {
        ..._ai(many.keys),
        'mine': const TagName(
          name: 'Mine',
          origin: NameOrigin.user,
          meaning: 'What I watch on Sundays',
        ),
        'typed': const TagName(name: 'Typed', origin: NameOrigin.user),
        'gone': const TagName(name: 'Gone', deleted: true),
      };
      final index = TagIndex.of(names, _using(many));

      final candidates = index.candidatesFor(_evidence(), _gaming);

      expect(candidates.first.tag.name, 'Mine');
      expect(candidates, hasLength(1 + maxAiTagCandidates));
      expect(_names(candidates), isNot(contains('Typed')));
      expect(_names(candidates), isNot(contains('Gone')));
    });

    test("put an AI tag named in the channel's name, description or "
        'titles before ones used more', () {
      final names = {
        ..._ai(many.keys),
        ..._ai(['Hermitcraft', 'Rare one']),
      };
      final index = TagIndex.of(names, _using(many));

      for (final evidence in [
        _evidence(title: 'Hermitcraft daily'),
        _evidence(description: 'Season 10 of HermitCraft, every week'),
        _evidence(titles: ['Building a farm | Hermitcraft 10']),
      ]) {
        final candidates = index.candidatesFor(evidence, _gaming);
        expect(_names(candidates).first, 'Hermitcraft');
        expect(_names(candidates), isNot(contains('Rare one')));
      }
    });

    test('name tags of several words only as written, in order', () {
      final names = _ai(['Mario Kart World', 'Mario Kart 8 Deluxe']);
      final index = TagIndex.of(names, const {});

      final candidates = index.candidatesFor(
        _evidence(titles: ['Mario Kart 8 Deluxe: 150cc online']),
        _gaming,
        maxAi: 1,
      );

      expect(_names(candidates), ['Mario Kart 8 Deluxe']);
    });

    test("then the most used in the channel's category, then the most used "
        'overall', () {
      final names = _ai(['Speedruns', 'Nintendo', 'Lofi', 'Jazz']);
      final index = TagIndex.of(names, {
        ..._using({'Speedruns': 2, 'Nintendo': 5}),
        ..._using({'Lofi': 9, 'Jazz': 1}, path: _music, prefix: 'UCm'),
      });

      expect(_names(index.candidatesFor(_evidence(), _gaming)), [
        'Nintendo',
        'Speedruns',
        'Lofi',
        'Jazz',
      ]);
    });

    test('keep a related tag in through its category, so Jev can tell them '
        'apart by meaning', () {
      final names = {
        ..._ai(many.keys),
        ..._ai(['Mario Kart World', 'Mario Kart 8 Deluxe']),
      };
      final index = TagIndex.of(names, {
        ..._using(many, path: _music, prefix: 'UCm'),
        ..._using({'Mario Kart World': 3}),
      });

      final candidates = index.candidatesFor(
        _evidence(titles: ['Mario Kart 8 Deluxe: 150cc online']),
        _gaming,
      );

      expect(_names(candidates).take(2), [
        'Mario Kart 8 Deluxe',
        'Mario Kart World',
      ]);
    });

    test('are found quickly: 3,000 tags for 12,000 channels', () {
      final words = ['speedrun', 'guide', 'review', 'live', 'music', 'remix'];
      final names = _ai([
        for (var i = 0; i < 3000; i++) '${words[i % 6]} topic $i',
      ]);
      final index = TagIndex.of(
        names,
        _using({
          for (var i = 0; i < 300; i++) '${words[i % 6]} topic $i': 1 + i % 7,
        }),
      );
      final evidence = [
        for (var c = 0; c < 12000; c++)
          _evidence(
            title: 'Channel $c',
            titles: [
              for (var t = 0; t < 30; t++)
                '${words[(c + t) % 6]} topic ${(c * 7 + t) % 4000} part $t',
            ],
          ),
      ];

      final watch = Stopwatch()..start();
      for (final e in evidence) {
        index.candidatesFor(e, _gaming);
      }
      final took = watch.elapsedMilliseconds;

      // ignore: avoid_print
      print('Candidates for 12,000 channels: ${took}ms');
      expect(took, lessThanOrEqualTo(_candidatesBudget));
    });
  });

  group('the tags a channel keeps', () {
    final names = {
      ..._ai(['VTuber', 'Music', 'Gaming']),
      'phaseconnect': const TagName(
        name: 'Phase Connect',
        origin: NameOrigin.user,
        meaning: 'A VTuber agency',
      ),
    };
    TagCandidate candidate(String name) =>
        (key: nameKey(name), tag: names[nameKey(name)]!);

    test("are the user's Jev kept, then AI's by how sure Jev was, then what "
        'Claude added, each once, at most 5', () {
      expect(
        rankTags(
          [
            (candidate('Music'), 0.7),
            (candidate('VTuber'), 0.95),
            (candidate('Phase Connect'), 0.65),
          ],
          ['vtuber', 'Hololive', 'Cover Artist', 'Roleplay'],
          names,
        ),
        ['Phase Connect', 'VTuber', 'Music', 'Hololive', 'Cover Artist'],
      );
    });

    test("count a tag of the user's that Claude names among the user's", () {
      expect(rankTags([(candidate('VTuber'), 0.9)], ['Phase Connect'], names), [
        'Phase Connect',
        'VTuber',
      ]);
    });
  });

  group("checking a channel for the user's tags", () {
    final names = {
      ..._ai(['VTuber', 'Music', 'Gaming', 'ASMR', 'Roleplay']),
      for (final name in ['Mine', 'Other', 'Third'])
        nameKey(name): TagName(
          name: name,
          origin: NameOrigin.user,
          meaning: 'What $name means',
        ),
    };

    test("adds one Jev is sure of, among the user's, and takes off one it "
        'is sure no longer fits, leaving the unsure', () {
      expect(
        applyTagCheck(
          ['VTuber', 'Other', 'Third'],
          {'mine': 0.8, 'other': 0.2, 'third': 0.5},
          names,
        ),
        ['Third', 'Mine', 'VTuber'],
      );
    });

    test('makes room past 5 by dropping the last AI tags', () {
      expect(
        applyTagCheck(
          ['VTuber', 'Music', 'Gaming', 'ASMR', 'Roleplay'],
          {'mine': 0.9},
          names,
        ),
        ['Mine', 'VTuber', 'Music', 'Gaming', 'ASMR'],
      );
    });

    group('on a channel whose tags the user edited', () {
      test('keeps one they added, however unsure Jev is', () {
        expect(
          applyTagCheck(
            ['Other'],
            {'other': 0.1},
            names,
            protectedKeys: {'other'},
          ),
          ['Other'],
        );
      });

      test('never puts back one they removed, however sure Jev is', () {
        expect(
          applyTagCheck(
            ['VTuber'],
            {'mine': 0.9},
            names,
            removedByUser: {'mine'},
          ),
          ['VTuber'],
        );
      });

      test('adds nothing when the 5 there are all theirs', () {
        const five = ['VTuber', 'Music', 'Gaming', 'ASMR', 'Roleplay'];
        expect(
          applyTagCheck(
            five,
            {'mine': 0.9},
            names,
            protectedKeys: {for (final tag in five) nameKey(tag)},
          ),
          five,
        );
      });
    });
  });
}

/// The candidates for 12,000 channels may take this long, in milliseconds:
/// the first measured run's time (2026-10-06, in the test VM: 377), three
/// times over.
const _candidatesBudget = 1131;
