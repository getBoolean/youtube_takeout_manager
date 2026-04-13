import 'dart:ui';

class SuperChatTier {
  final Color headerColor;
  final Color? bodyColor;
  final Color textColor;
  final bool showBody;

  const SuperChatTier({
    required this.headerColor,
    this.bodyColor,
    required this.textColor,
    required this.showBody,
  });
}

const _white = Color(0xFFFFFFFF);
const _dark = Color(0xFF212121);
const _micros = 1000000;

const _tiers = [
  (min: 100.0, tier: SuperChatTier(headerColor: Color(0xFFD00000), bodyColor: Color(0xFFB71C1C), textColor: _white, showBody: true)),
  (min: 50.0, tier: SuperChatTier(headerColor: Color(0xFFC2185B), bodyColor: Color(0xFFAD1457), textColor: _white, showBody: true)),
  (min: 20.0, tier: SuperChatTier(headerColor: Color(0xFFE65100), bodyColor: Color(0xFFBF360C), textColor: _white, showBody: true)),
  (min: 10.0, tier: SuperChatTier(headerColor: Color(0xFFFFB300), bodyColor: Color(0xFFF9A825), textColor: _dark, showBody: true)),
  (min: 5.0, tier: SuperChatTier(headerColor: Color(0xFF00BFA5), bodyColor: Color(0xFF00A88F), textColor: _white, showBody: true)),
  (min: 2.0, tier: SuperChatTier(headerColor: Color(0xFF00B8D4), textColor: _white, showBody: false)),
  (min: 1.0, tier: SuperChatTier(headerColor: Color(0xFF1565C0), textColor: _white, showBody: false)),
];

/// Returns the Super Chat tier for the given [priceMicros], or null if the
/// price is below the minimum threshold ($1.00 = 1,000,000 micros).
///
/// Prices in Google Takeout CSVs are stored in micros (6 extra zeros).
SuperChatTier? getSuperChatTier(double priceMicros) {
  final dollars = priceMicros / _micros;
  if (dollars < 1.0) return null;
  for (final entry in _tiers) {
    if (dollars >= entry.min) return entry.tier;
  }
  return null;
}

/// Formats a price (in micros) and currency code for display in the Super Chat
/// header. USD gets a `$` prefix; all others show the amount followed by the
/// code.
String formatSuperChatPrice(double priceMicros, String currencyCode) {
  final dollars = priceMicros / _micros;
  final formatted = dollars.toStringAsFixed(2);
  if (currencyCode == 'USD') {
    return '\$$formatted USD';
  }
  return '$formatted $currencyCode';
}
