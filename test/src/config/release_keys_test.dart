import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Names that would put a build's AI keys into an app built by CI, where
/// anyone could pull them out of the download.
const _leaks = [
  'dart-define-from-file',
  'TYPESAFE_API_KEY',
  'ANTHROPIC_API_KEY',
  'ANTHROPIC_MODEL',
];

/// The workflow files in [directory] that would build with AI keys, and
/// what gives each away.
Map<String, List<String>> _workflowsWithKeys(Directory directory) => {
  for (final file in directory.listSync().whereType<File>())
    if (file.path.endsWith('.yml') || file.path.endsWith('.yaml'))
      if ([
            for (final leak in _leaks)
              if (file.readAsStringSync().contains(leak)) leak,
          ]
          case final found when found.isNotEmpty)
        file.uri.pathSegments.last: found,
};

void main() {
  test('a workflow that builds with the .env file is caught', () {
    final dir = Directory.systemTemp.createTempSync('workflows');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/ok.yml').writeAsStringSync('run: flutter build web');
    File(
      '${dir.path}/leaky.yml',
    ).writeAsStringSync('run: flutter build web --dart-define-from-file=.env');
    File(
      '${dir.path}/secret.yaml',
    ).writeAsStringSync('env:\n  ANTHROPIC_API_KEY: \${{ secrets.X }}');

    expect(_workflowsWithKeys(dir), {
      'leaky.yml': ['dart-define-from-file'],
      'secret.yaml': ['ANTHROPIC_API_KEY'],
    });
  });

  test('no CI or release build gets the AI keys', () {
    expect(_workflowsWithKeys(Directory('.github/workflows')), isEmpty);
  });
}
