// Paths and helpers the screenshot steps share. Paths are relative to the
// project root, where run.dart is run from.

import 'dart:io';

import 'package:path/path.dart' as p;

/// The generated takeout, pictures and raw screenshots, ignored with the rest
/// of build/.
const work = 'build/screenshots';

/// The images the README shows.
const images = 'tool/screenshots/images';

/// Where the web build is served: the origin registered for web sign-in.
const app = 'http://localhost:9000';

void log(String message) => stdout.writeln(message);

/// A `file:` URL for [path], for pages that load local images.
String fileUrl(String path) => Uri.file(p.absolute(path)).toString();

const _types = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.mjs': 'text/javascript',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.css': 'text/css',
};

/// Serves build/web on [app], sending paths it doesn't have to index.html.
Future<HttpServer> serveWebBuild() async {
  const root = 'build/web';
  if (!File('$root/index.html').existsSync()) {
    throw StateError(
      'No web build: run `flutter build web --dart-define-from-file=.env` first.',
    );
  }
  final port = Uri.parse(app).port;
  final HttpServer server;
  try {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  } on SocketException catch (e) {
    throw StateError(
      'Port $port is in use, maybe by another run or `flutter run`: $e',
    );
  }
  server.listen((request) async {
    var file = File(p.joinAll([root, ...request.uri.pathSegments]));
    if (!file.existsSync()) file = File('$root/index.html');
    request.response.headers
      ..contentType = ContentType.parse(
        _types[p.extension(file.path)] ?? 'application/octet-stream',
      )
      ..set(HttpHeaders.cacheControlHeader, 'no-store');
    await request.response.addStream(file.openRead());
    await request.response.close();
  });
  return server;
}
