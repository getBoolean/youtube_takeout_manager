import 'dart:math';

import 'package:dart_mappable/dart_mappable.dart';

part 'model_capabilities.mapper.dart';

/// What a Claude model can do, as the Models API says: nothing about it is
/// guessed from its name.
@MappableClass()
class ModelCapabilities with ModelCapabilitiesMappable {
  /// The model as it's asked for, e.g. `claude-haiku-4-5`.
  final String id;

  /// Whether it answers in a shape a JSON schema gives; categorizing needs
  /// it to.
  final bool structuredOutputs;

  /// Whether it can be asked to think little.
  final bool lowEffort;

  /// The longest answer it gives, when known.
  final int? maxTokens;

  const ModelCapabilities({
    required this.id,
    required this.structuredOutputs,
    required this.lowEffort,
    this.maxTokens,
  });

  /// [id]'s capabilities from `GET /v1/models/{id}`: what isn't there counts
  /// as unsupported.
  factory ModelCapabilities.fromModelsApi(
    String id,
    Map<String, Object?> json,
  ) => ModelCapabilities(
    id: id,
    structuredOutputs: switch (json) {
      {'capabilities': {'structured_outputs': {'supported': true}}} => true,
      _ => false,
    },
    lowEffort: switch (json) {
      {'capabilities': {'effort': {'low': {'supported': true}}}} => true,
      _ => false,
    },
    maxTokens: switch (json) {
      {'max_tokens': final int tokens} when tokens > 0 => tokens,
      _ => null,
    },
  );

  /// How long an answer may be: 1024 tokens, or the model's maximum when
  /// that's less.
  int get answerTokens => min(1024, maxTokens ?? 1024);
}
