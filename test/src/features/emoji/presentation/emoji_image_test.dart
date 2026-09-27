import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/emoji/presentation/emoji_image.dart';

void main() {
  // Network images always fail under flutter_test, like a deleted emoji.
  testWidgets('missing emoji image shows a visible placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            EmojiImage(url: 'https://yt3.googleusercontent.com/gone', size: 20),
            EmojiImage(
              url: 'https://yt3.googleusercontent.com/gone',
              size: 56,
              explainMissing: true,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(EmojiImage.placeholderKey), findsNWidgets(2));
    // Only the one asked to explain says why.
    expect(find.textContaining('available'), findsOneWidget);
  });

  testWidgets('says when Takeout had no image URL', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EmojiImage(
          url: 'Failed to get emoji URL',
          size: 56,
          explainMissing: true,
        ),
      ),
    );

    expect(find.byKey(EmojiImage.placeholderKey), findsOneWidget);
    expect(find.textContaining('Takeout'), findsOneWidget);
  });
}
