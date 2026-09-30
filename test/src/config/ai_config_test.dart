import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/config/ai_config.dart';

void main() {
  group('the Claude model', () {
    test('is the default when none is set', () {
      expect(resolveAnthropicModel(''), defaultAnthropicModel);
    });

    test('is the default when set to only spaces', () {
      expect(resolveAnthropicModel('  '), defaultAnthropicModel);
    });

    test('is the one set, without surrounding spaces', () {
      expect(resolveAnthropicModel(' claude-sonnet-5 '), 'claude-sonnet-5');
    });
  });

  group('AI keys', () {
    test('turn on only the tiers they are given', () {
      const none = AiKeys(typesafe: '', anthropic: '');
      const jevOnly = AiKeys(typesafe: 'jv_live_x', anthropic: '');
      const claudeOnly = AiKeys(typesafe: '', anthropic: 'sk-ant-x');

      expect((none.hasJev, none.hasClaude, none.hasAny), (false, false, false));
      expect((jevOnly.hasJev, jevOnly.hasClaude), (true, false));
      expect((claudeOnly.hasJev, claudeOnly.hasClaude), (false, true));
      expect(claudeOnly.hasAny, isTrue);
    });

    test('a key of only spaces counts as none', () {
      const blank = AiKeys(typesafe: ' ', anthropic: '\t');

      expect(blank.hasAny, isFalse);
    });
  });
}
