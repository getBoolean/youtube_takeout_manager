import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/interactions/domain/interaction_status.dart';
import 'package:youtube_takeout_manager/src/features/interactions/presentation/interaction_status_style.dart';

void main() {
  final scheme = ColorScheme.fromSeed(seedColor: Colors.red);

  test('each status other than active has its own icon', () {
    expect(InteractionStatus.deleted.icon, Icons.delete_outline);
    expect(InteractionStatus.failed.icon, Icons.error_outline);
    expect(InteractionStatus.queued.icon, Icons.schedule);
    expect(InteractionStatus.active.icon, isNull);
  });

  test('deleted and failed items show in the error colour, queued ones in '
      'the tertiary one', () {
    expect(InteractionStatus.deleted.color(scheme), scheme.error);
    expect(InteractionStatus.failed.color(scheme), scheme.error);
    expect(InteractionStatus.queued.color(scheme), scheme.tertiary);
    expect(InteractionStatus.active.color(scheme), isNull);
  });
}
