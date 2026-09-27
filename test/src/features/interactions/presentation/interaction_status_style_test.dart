import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction_status.dart';
import 'package:youtube_takeout_manager/src/features/interactions/presentation/interaction_status_style.dart';

void main() {
  test('each status other than active has its own icon', () {
    final icons = [
      for (final s in InteractionStatus.values)
        if (s != InteractionStatus.active) s.icon,
    ];
    expect(icons, everyElement(isNotNull));
    expect(icons.toSet(), hasLength(icons.length));
    expect(InteractionStatus.active.icon, isNull);
  });
}
