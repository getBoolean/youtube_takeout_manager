// Regenerates the README screenshots in tool/screenshots/images/: the web
// build, running in Chrome, imports the made-up takeout in takeout.json and
// is photographed at phone size in light and dark.
//
// Run from the project root:
//   flutter build web --dart-define-from-file=.env
//   dart run tool/screenshots/run.dart
//
// The first run downloads Chrome into .dart_tool/.

import 'dart:io';

import 'package:puppeteer/puppeteer.dart';

import 'common.dart';
import 'hero.dart';
import 'pictures.dart';
import 'shoot.dart';
import 'takeout.dart';

Future<void> main() async {
  final takeout = loadTakeout();
  final dir = Directory(work);
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);
  File('$work/$takeoutFileName').writeAsBytesSync(takeout.zip);

  final server = await serveWebBuild();
  final browser = await puppeteer.launch();
  try {
    await drawPictures(browser, takeout);
    for (final scheme in ['light', 'dark']) {
      await takeScreenshots(browser, takeout, scheme);
    }
    await composeHeroes(browser);
  } finally {
    await browser.close();
    await server.close(force: true);
  }
}
