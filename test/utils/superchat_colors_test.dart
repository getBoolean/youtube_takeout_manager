import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_takeout_manager/utils/superchat_colors.dart';

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

    test('returns blue tier for \$1–\$1.99', () {
      final tier = getSuperChatTier(1000000)!; // \$1.00
      expect(tier.headerColor, const Color(0xFF1565C0));
      expect(tier.bodyColor, isNull);
      expect(tier.showBody, isFalse);
      expect(tier.textColor, const Color(0xFFFFFFFF));

      expect(getSuperChatTier(1990000)!.headerColor, const Color(0xFF1565C0)); // \$1.99
    });

    test('returns light blue tier for \$2–\$4.99', () {
      final tier = getSuperChatTier(2000000)!; // \$2.00
      expect(tier.headerColor, const Color(0xFF00B8D4));
      expect(tier.showBody, isFalse);

      expect(getSuperChatTier(4990000)!.headerColor, const Color(0xFF00B8D4)); // \$4.99
    });

    test('returns green tier for \$5–\$9.99', () {
      final tier = getSuperChatTier(5000000)!; // \$5.00
      expect(tier.headerColor, const Color(0xFF00BFA5));
      expect(tier.bodyColor, const Color(0xFF00A88F));
      expect(tier.showBody, isTrue);

      expect(getSuperChatTier(9990000)!.headerColor, const Color(0xFF00BFA5)); // \$9.99
    });

    test('returns yellow tier for \$10–\$19.99', () {
      final tier = getSuperChatTier(10000000)!; // \$10.00
      expect(tier.headerColor, const Color(0xFFFFB300));
      expect(tier.bodyColor, const Color(0xFFF9A825));
      expect(tier.textColor, const Color(0xFF212121));
    });

    test('returns orange tier for \$20–\$49.99', () {
      final tier = getSuperChatTier(20000000)!; // \$20.00
      expect(tier.headerColor, const Color(0xFFE65100));
      expect(tier.bodyColor, const Color(0xFFBF360C));
    });

    test('returns magenta tier for \$50–\$99.99', () {
      final tier = getSuperChatTier(50000000)!; // \$50.00
      expect(tier.headerColor, const Color(0xFFC2185B));
      expect(tier.bodyColor, const Color(0xFFAD1457));
    });

    test('returns red tier for \$100+', () {
      final tier = getSuperChatTier(100000000)!; // \$100.00
      expect(tier.headerColor, const Color(0xFFD00000));
      expect(tier.bodyColor, const Color(0xFFB71C1C));

      // Very large amounts still red
      expect(getSuperChatTier(9999990000)!.headerColor, const Color(0xFFD00000)); // \$9999.99
    });

    test('boundary: \$1.99 is blue, \$2.00 is light blue', () {
      expect(getSuperChatTier(1990000)!.headerColor, const Color(0xFF1565C0)); // \$1.99
      expect(getSuperChatTier(2000000)!.headerColor, const Color(0xFF00B8D4)); // \$2.00
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
