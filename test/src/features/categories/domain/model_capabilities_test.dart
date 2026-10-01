import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/categories/domain/model_capabilities.dart';

void main() {
  group("a model's capabilities, read from the Models API", () {
    test('say what it supports and how long it may answer', () {
      final model = ModelCapabilities.fromModelsApi('claude-sonnet-5', {
        'id': 'claude-sonnet-5-20260801',
        'type': 'model',
        'max_tokens': 64000,
        'capabilities': {
          'structured_outputs': {'supported': true},
          'effort': {
            'supported': true,
            'low': {'supported': true},
            'high': {'supported': true},
          },
        },
      });

      expect(model.id, 'claude-sonnet-5');
      expect(model.structuredOutputs, isTrue);
      expect(model.lowEffort, isTrue);
      expect(model.maxTokens, 64000);
    });

    test('count what is missing as unsupported', () {
      final model = ModelCapabilities.fromModelsApi('claude-haiku-4-5', {
        'id': 'claude-haiku-4-5-20251001',
        'type': 'model',
      });

      expect(model.structuredOutputs, isFalse);
      expect(model.lowEffort, isFalse);
      expect(model.maxTokens, isNull);
    });

    test('count a capability said to be unsupported as unsupported', () {
      final model = ModelCapabilities.fromModelsApi('claude-x', {
        'capabilities': {
          'structured_outputs': {'supported': false},
          'effort': {
            'low': {'supported': false},
          },
        },
      });

      expect(model.structuredOutputs, isFalse);
      expect(model.lowEffort, isFalse);
    });
  });

  group('an answer may be', () {
    test('1024 tokens long', () {
      const model = ModelCapabilities(
        id: 'm',
        structuredOutputs: true,
        lowEffort: false,
        maxTokens: 64000,
      );

      expect(model.answerTokens, 1024);
    });

    test("as long as the model's maximum, when that's less", () {
      const model = ModelCapabilities(
        id: 'm',
        structuredOutputs: true,
        lowEffort: false,
        maxTokens: 512,
      );

      expect(model.answerTokens, 512);
    });

    test('1024 tokens long when the maximum is unknown', () {
      const model = ModelCapabilities(
        id: 'm',
        structuredOutputs: true,
        lowEffort: false,
      );

      expect(model.answerTokens, 1024);
    });
  });
}
