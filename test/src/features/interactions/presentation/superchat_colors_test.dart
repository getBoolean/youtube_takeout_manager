import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/interactions/presentation/superchat_colors.dart';

void main() {
  group('getSuperChatTier', () {
    test('returns null for priceMicros <= 0', () {
      expect(getSuperChatTier(0), isNull);
      expect(getSuperChatTier(-5000000), isNull);
    });

    test('returns null for priceMicros < \$1 (1000000)', () {
      expect(getSuperChatTier(500000), isNull);
      expect(getSuperChatTier(999999), isNull);
    });

    // YouTube's Super Chat tiers start at these dollar amounts.
    const boundaries = [1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0];
    double micros(double dollars) => dollars * 1000000;

    test('each tier runs up to the next boundary', () {
      for (var i = 0; i < boundaries.length - 1; i++) {
        final start = boundaries[i];
        final next = boundaries[i + 1];
        final tier = getSuperChatTier(micros(start));
        expect(tier, isNotNull, reason: '\$$start');
        expect(
          getSuperChatTier(micros(next - 0.01)),
          same(tier),
          reason: '\$${next - 0.01} is in the \$$start tier',
        );
        expect(
          getSuperChatTier(micros(next)),
          isNot(same(tier)),
          reason: '\$$next starts a new tier',
        );
      }
    });

    test('very large amounts stay in the top tier', () {
      expect(
        getSuperChatTier(micros(9999.99)),
        same(getSuperChatTier(micros(boundaries.last))),
      );
    });

    test('every tier has its own header color', () {
      final colors = {
        for (final dollars in boundaries)
          getSuperChatTier(micros(dollars))!.headerColor,
      };
      expect(colors, hasLength(boundaries.length));
    });

    test('only tiers from \$5 show a message body', () {
      for (final dollars in [1.0, 2.0, 4.99]) {
        final tier = getSuperChatTier(micros(dollars))!;
        expect(tier.showBody, isFalse, reason: '\$$dollars');
      }
      for (final dollars in [5.0, 10.0, 20.0, 50.0, 100.0]) {
        final tier = getSuperChatTier(micros(dollars))!;
        expect(tier.showBody, isTrue, reason: '\$$dollars');
        expect(tier.bodyColor, isNotNull, reason: '\$$dollars');
      }
    });
  });

  group('formatSuperChatPrice', () {
    test('formats USD with dollar sign', () {
      expect(formatSuperChatPrice(15000000, 'USD'), '\$15.00 USD'); // \$15.00
    });

    test('formats other currencies with code only', () {
      expect(formatSuperChatPrice(15000000, 'EUR'), '15.00 EUR');
      expect(formatSuperChatPrice(1500000000, 'JPY'), '1500.00 JPY');
    });

    test('formats with two decimal places', () {
      expect(formatSuperChatPrice(5500000, 'USD'), '\$5.50 USD'); // \$5.50
      expect(formatSuperChatPrice(10000000, 'USD'), '\$10.00 USD'); // \$10.00
    });
  });
}
