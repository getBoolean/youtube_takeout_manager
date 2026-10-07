import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/name_key.dart';

void main() {
  group('names share a key when they differ only by', () {
    test('hyphens and spaces', () {
      expect(nameKey('Hip-hop'), nameKey('Hip hop'));
      expect(nameKey('Hip hop'), nameKey('hiphop'));
    });

    test('case and accents', () {
      expect(nameKey('Pokémon'), nameKey('pokemon'));
      expect(nameKey('POKÉMON'), nameKey('Pokemon'));
    });

    test('punctuation', () {
      expect(nameKey("Let's Plays"), nameKey('Lets plays'));
      expect(nameKey('R&B'), nameKey('RB'));
    });
  });

  group('names keep keys of their own when they differ by', () {
    test('digits', () {
      expect(nameKey('Top 10'), isNot(nameKey('Top 100')));
    });

    test('vowel signs in Devanagari', () {
      expect(nameKey('कला'), isNot(nameKey('काला')));
    });

    test('a sharp, as in C#', () {
      expect(nameKey('C#'), isNot(nameKey('C')));
      expect(nameKey('C# programming'), isNot(nameKey('C programming')));
      expect(nameKey('F#'), nameKey('f #'));
    });

    test('symbols, which are no punctuation', () {
      expect(nameKey('C++'), isNot(nameKey('C#')));
      expect(nameKey('C++'), nameKey('c ++'));
    });

    test('letters in another script', () {
      expect(nameKey('Аниме'), isNot(nameKey('Anime')));
    });
  });

  test('a name of only punctuation keeps a key of its own', () {
    expect(nameKey('!!!'), isNotEmpty);
    expect(nameKey('!!!'), isNot(nameKey('???')));
  });

  test("text splits into its words' keys, which join into a name's key", () {
    expect(nameKeyWords('Mario Kart 8 Deluxe: 150cc, ONLINE!'), [
      'mario',
      'kart',
      '8',
      'deluxe',
      '150cc',
      'online',
    ]);
    expect(
      nameKeyWords('Speed-runs of Pokémon').join(),
      nameKey('Speed-runs of Pokémon'),
    );
  });
}
