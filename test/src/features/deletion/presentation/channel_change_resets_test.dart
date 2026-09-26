import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youtube_takeout_manager/src/features/deletion/application/script_deletion_ids.dart';
import 'package:youtube_takeout_manager/src/features/deletion/presentation/deletion_selection_controller.dart';
import 'package:youtube_takeout_manager/src/features/takeout/application/viewed_takeout_providers.dart';

class _Viewed extends Notifier<String?> {
  @override
  String? build() => 'UCa';

  void set(String channelId) => state = channelId;
}

final _viewed = NotifierProvider<_Viewed, String?>(_Viewed.new);

void main() {
  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        viewedChannelIdProvider.overrideWith((ref) => ref.watch(_viewed)),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('the selection clears when another channel is viewed', () {
    final c = container();
    c.listen(deletionSetProvider, (_, _) {});
    c.read(deletionSetProvider.notifier).addAll({'c1'});

    c.read(_viewed.notifier).set('UCb');

    expect(c.read(deletionSetProvider), isEmpty);
  });

  test('the My Activity script forgets its items when another channel is '
      'viewed', () {
    final c = container();
    c.listen(scriptDeletionIdsProvider, (_, _) {});
    c.read(scriptDeletionIdsProvider.notifier).set({'c1'});

    c.read(_viewed.notifier).set('UCb');

    expect(c.read(scriptDeletionIdsProvider), isEmpty);
  });
}
