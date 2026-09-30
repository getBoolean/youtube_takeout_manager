/// The Claude model categorizing channels when the build names none.
const defaultAnthropicModel = 'claude-haiku-4-5';

const _typesafeApiKey = String.fromEnvironment('TYPESAFE_API_KEY');
const _anthropicApiKey = String.fromEnvironment('ANTHROPIC_API_KEY');
const _anthropicModel = String.fromEnvironment('ANTHROPIC_MODEL');

/// The model [configured] names, or [defaultAnthropicModel] when it names
/// none: `ANTHROPIC_MODEL=` in `.env` gives an empty string, not a missing
/// value.
String resolveAnthropicModel(String configured) {
  final model = configured.trim();
  return model.isEmpty ? defaultAnthropicModel : model;
}

/// The Claude model this build categorizes channels with.
final anthropicModel = resolveAnthropicModel(_anthropicModel);

/// The AI services channels can be categorized with.
enum AiService {
  /// TypeSafe's Jev: cheap checks and picks from known categories.
  jev,

  /// Anthropic's Claude: names categories Jev can't settle.
  claude,
}

/// The API keys for the AI services; empty for a service without one.
class AiKeys {
  final String typesafe;
  final String anthropic;

  const AiKeys({this.typesafe = '', this.anthropic = ''});

  static const none = AiKeys();

  /// [service]'s key, empty without one.
  String keyFor(AiService service) => switch (service) {
    AiService.jev => typesafe,
    AiService.claude => anthropic,
  }.trim();

  /// Whether [service] has a key.
  bool has(AiService service) => keyFor(service).isNotEmpty;

  bool get hasJev => has(AiService.jev);
  bool get hasClaude => has(AiService.claude);
  bool get hasAny => hasJev || hasClaude;

  @override
  bool operator ==(Object other) =>
      other is AiKeys &&
      other.keyFor(AiService.jev) == keyFor(AiService.jev) &&
      other.keyFor(AiService.claude) == keyFor(AiService.claude);

  @override
  int get hashCode =>
      Object.hash(keyFor(AiService.jev), keyFor(AiService.claude));

  /// Never shows the keys themselves, e.g. in logs.
  @override
  String toString() => 'AiKeys(jev: $hasJev, claude: $hasClaude)';
}

/// The keys this build was made with. Only for personal builds: anyone can
/// read a key out of an app, so release builds never get them.
const buildAiKeys = AiKeys(
  typesafe: _typesafeApiKey,
  anthropic: _anthropicApiKey,
);
