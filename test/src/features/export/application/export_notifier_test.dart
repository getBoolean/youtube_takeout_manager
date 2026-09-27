import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:youtube_takeout_manager/src/features/comments/domain/comment.dart';
import 'package:youtube_takeout_manager/src/features/export/application/export_notifier.dart';
import 'package:youtube_takeout_manager/src/features/export/data/export_file_repository.dart';
import 'package:youtube_takeout_manager/src/features/export/domain/export_format.dart';

/// Keeps what would be saved; answers as [saves] says.
class _Files extends ExportFileRepository {
  bool Function() saves;
  final saved = <({String content, String filename, ExportFormat format})>[];

  _Files(this.saves);

  @override
  Future<bool> save(String content, String filename, ExportFormat format) {
    saved.add((content: content, filename: filename, format: format));
    return Future(saves);
  }
}

final _comment = Comment(
  commentId: 'c1',
  channelId: 'UC1',
  createdAt: DateTime.utc(2026, 1, 2),
  price: 0,
  videoId: 'v1',
  rawCommentText: '{"text":"Hello"}',
  displayText: 'Hello',
);

void main() {
  late _Files files;
  late ProviderContainer c;

  setUp(() {
    files = _Files(() => true);
    c = ProviderContainer(
      overrides: [exportFileRepositoryProvider.overrideWithValue(files)],
    );
    addTearDown(c.dispose);
  });

  Future<ExportResult> export(ExportFormat format) => c
      .read(exportProvider.notifier)
      .exportData(
        comments: [_comment],
        liveChats: const [],
        format: format,
        filename: 'Chan_export',
        channelNames: {'UC1': 'Chan'},
      );

  test('saves the items in the picked format', () async {
    expect(await export(ExportFormat.csv), ExportResult.success);
    expect(await export(ExportFormat.json), ExportResult.success);

    expect(files.saved.map((s) => (s.filename, s.format)), [
      ('Chan_export', ExportFormat.csv),
      ('Chan_export', ExportFormat.json),
    ]);
    expect(files.saved[0].content, contains('comment,c1,UC1,Chan,v1,'));
    expect(files.saved[1].content, contains('"channelName": "Chan"'));
  });

  test('says when the user cancelled', () async {
    files.saves = () => false;
    expect(await export(ExportFormat.csv), ExportResult.cancelled);
  });

  test('says when saving failed', () async {
    files.saves = () => throw Exception('disk full');
    expect(await export(ExportFormat.csv), ExportResult.error);
  });

  test('is exporting only while saving', () async {
    expect(c.read(exportProvider), isFalse);
    final done = export(ExportFormat.csv);
    expect(c.read(exportProvider), isTrue);
    await done;
    expect(c.read(exportProvider), isFalse);
  });
}
