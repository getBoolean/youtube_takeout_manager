import 'dart:async';
import 'dart:convert';

import 'package:youtube_takeout_manager/src/features/categories/data/ai_errors.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/ai_request.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/anthropic_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/typesafe_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/model_capabilities.dart';

/// A request Claude was sent: what it asked for ('category' or 'tags'),
/// about which channels, as told, under what, and how long its answer
/// could be.
typedef ClaudeAsked = ({
  String kind,
  List<Map<String, Object?>> channels,
  String system,
  int? maxTokens,
});

/// Claude, answering each request about several channels, each by its id,
/// from a script: [category] for a category request (its tags from
/// [tags]), [tags] for a tags request; a tag is a name, or a name with its
/// meaning as `{'name', 'meaning'}`. [answer], when given, answers a
/// request's channels itself, leaving out those it leaves out. It waits for
/// [hold] before answering, and fails with [failure] when set. Keeps every
/// request.
class ScriptedClaude extends AnthropicRepository {
  ScriptedClaude({
    this.category = const {'parent': 'Knowledge'},
    this.tags = const [],
    this.failure,
    this.hold,
    this.structuredOutputs = true,
    this.capabilitiesFailure,
    this.answer,
  });

  final Map<String, Object?> category;
  final List<Object?> tags;
  AiFailure? failure;
  Completer<void>? hold;
  final bool structuredOutputs;

  /// Why its model can't be looked up, if it can't.
  final AiFailure? capabilitiesFailure;
  final List<Map<String, Object?>> Function(
    String kind,
    List<Map<String, Object?>> channels,
  )?
  answer;

  final requests = <ClaudeAsked>[];

  /// The models whose capabilities were asked for.
  final capabilitiesAsked = <String>[];

  /// Each request's user message, as sent.
  final asked = <String>[];

  /// What was asked about each channel, request by request: 'category: X'
  /// or 'tags: X', X being the channel's name.
  List<String> get kinds => [
    for (final request in requests)
      for (final channel in request.channels)
        '${request.kind}: ${channel['channel']}',
  ];

  @override
  Future<ModelCapabilities> capabilities({
    required String apiKey,
    required String model,
  }) async {
    capabilitiesAsked.add(model);
    if (capabilitiesFailure case final failure?) throw failure;
    return ModelCapabilities(
      id: model,
      structuredOutputs: structuredOutputs,
      lowEffort: false,
    );
  }

  @override
  Future<Map<String, Object?>> structured({
    required String apiKey,
    required ModelCapabilities model,
    required String system,
    required String user,
    required Map<String, Object?> schema,
    int? maxTokens,
    int? expectedOutputTokens,
    void Function(int inputTokens, int outputTokens)? onUsage,
    RetryPolicy? policy,
  }) async {
    final item =
        ((schema['properties']! as Map)['answers']! as Map)['items']! as Map;
    final kind = (item['properties']! as Map).containsKey('parent')
        ? 'category'
        : 'tags';
    final channels = [
      for (final channel in (jsonDecode(user) as Map)['channels'] as List)
        (channel as Map).cast<String, Object?>(),
    ];
    asked.add(user);
    requests.add((
      kind: kind,
      channels: channels,
      system: system,
      maxTokens: maxTokens,
    ));
    await hold?.future;
    if (failure case final failure?) throw failure;
    onUsage?.call(1000 * channels.length, 50 * channels.length);
    final named = [
      for (final tag in tags)
        tag is String ? {'name': tag, 'meaning': ''} : tag,
    ];
    return {
      'answers':
          answer?.call(kind, channels) ??
          [
            for (final channel in channels)
              {
                'id': channel['id'],
                if (kind == 'category') ...{
                  'child': '',
                  'emoji': '',
                  'reason': '',
                  ...category,
                },
                'tags': named,
              },
          ],
    };
  }
}

/// Jev, answering from a script: how likely yes is for each category or
/// tag it's asked about, by the name it's asked about in quotes ([fits]),
/// how likely yes is that a channel is about something no tag names
/// ([other]), and the option it picks of a choice, with how likely each
/// is ([parent], [child]): the first, unsure, when not scripted. Fails
/// with [failure] when set. Keeps the questions of each request.
class ScriptedJev extends TypeSafeRepository {
  ScriptedJev({
    this.fits = const {},
    this.other = 0,
    this.parent,
    this.child,
    this.failure,
  });

  final Map<String, double> fits;
  final double other;
  final Map<String, double>? parent;
  final Map<String, double>? child;
  AiFailure? failure;

  /// The questions asked, per request.
  final requests = <Map<String, JevQuestion>>[];

  @override
  Future<Map<String, JevAnswer>> ask({
    required String apiKey,
    required Object state,
    required Map<String, JevQuestion> questions,
  }) async {
    if (failure case final failure?) throw failure;
    requests.add(questions);
    return {
      for (final MapEntry(:key, :value) in questions.entries)
        key: switch (value) {
          JevNoul() when key == 'other' => NoulAnswer(other),
          JevNoul(:final instructions) => NoulAnswer(
            fits.entries
                    .where((f) => instructions.contains('"${f.key}"'))
                    .firstOrNull
                    ?.value ??
                0,
          ),
          JevChoice(:final options) => _choose(
            options,
            key == 'parent' ? parent : child,
          ),
        },
    };
  }

  /// Picks the likeliest of [options] by the names in [odds].
  static ChoiceAnswer _choose(
    Map<String, String?> options,
    Map<String, double>? odds,
  ) {
    String keyOf(String name) => options.entries
        .firstWhere(
          (o) => o.key == name || (o.value?.startsWith(name) ?? false),
          orElse: () => options.entries.first,
        )
        .key;
    final probabilities = {
      for (final MapEntry(:key, :value) in (odds ?? const {}).entries)
        keyOf(key): value,
    };
    if (probabilities.isEmpty) {
      return ChoiceAnswer(
        choice: options.keys.first,
        probabilities: {options.keys.first: 0},
        confidence: 0,
      );
    }
    final best = probabilities.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    return ChoiceAnswer(
      choice: best.key,
      probabilities: probabilities,
      confidence: best.value,
    );
  }
}
