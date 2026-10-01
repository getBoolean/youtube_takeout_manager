import 'package:youtube_takeout_manager/src/features/categories/data/ai_errors.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/anthropic_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/data/typesafe_repository.dart';
import 'package:youtube_takeout_manager/src/features/categories/domain/model_capabilities.dart';

/// Jev, whose key checks work, or fail with [failure], recording the keys
/// checked. Asks nothing.
class CheckedJev extends TypeSafeRepository {
  CheckedJev([this.failure]);

  final AiFailure? failure;
  final checked = <String>[];

  @override
  Future<void> checkKey(String apiKey) async {
    checked.add(apiKey);
    if (failure case final failure?) throw failure;
  }
}

/// Claude, whose key checks give a model that answers in shapes when
/// [structuredOutputs], or fail with [failure], recording the keys checked.
/// Asks nothing.
class CheckedClaude extends AnthropicRepository {
  CheckedClaude({this.failure, this.structuredOutputs = true})
    : super(browser: false);

  final AiFailure? failure;
  final bool structuredOutputs;
  final checked = <String>[];

  @override
  Future<ModelCapabilities> capabilities({
    required String apiKey,
    required String model,
  }) async {
    checked.add(apiKey);
    if (failure case final failure?) throw failure;
    return ModelCapabilities(
      id: model,
      structuredOutputs: structuredOutputs,
      lowEffort: false,
      maxTokens: 64000,
    );
  }
}
