import 'dart:io';

/// Compiles every squadron web worker entry point (`lib/**/*.web.g.dart`)
/// to JavaScript in `web/workers`, where the web app loads them. Run it
/// before `flutter build web` or `flutter run -d chrome`, and again after
/// changing worker code.
Future<void> main() async {
  final entries = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.web.g.dart'));
  await Directory('web/workers').create(recursive: true);
  for (final entry in entries) {
    final name = entry.uri.pathSegments.last;
    stdout.writeln('Compiling $name');
    final result = await Process.run(Platform.resolvedExecutable, [
      'compile',
      'js',
      '-O2',
      entry.path,
      '-o',
      'web/workers/$name.js',
    ]);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode != 0) exit(result.exitCode);
  }
}
