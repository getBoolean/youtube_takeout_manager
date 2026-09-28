// Imports the made-up takeout into a fresh phone-sized browser and takes the
// README screenshots. Taps are at fixed spots on a 390x844 screen, so a
// layout change can move what they hit; look over new screenshots before
// committing them.

import 'dart:io';

import 'package:puppeteer/puppeteer.dart';

import 'common.dart';
import 'pictures.dart';
import 'takeout.dart';

/// Where [takeScreenshots] saves the screenshots in [scheme].
String shotsDir(String scheme) => '$work/shots/$scheme';

final _thumbnailUrl = RegExp(r'^https://i\.ytimg\.com/vi/([^/]+)/');
final _pictureUrl = RegExp(r'^https://yt3\.ggpht\.com/ytc/([^=]+)=');

/// The drawn picture for a thumbnail or channel picture [url], or null for
/// anything else.
String? _pictureFor(String url) {
  if (_thumbnailUrl.firstMatch(url) case final m?) {
    return '$thumbnailsDir/${m[1]}.png';
  }
  if (_pictureUrl.firstMatch(url) case final m?) {
    return '$avatarsDir/${m[1]}.png';
  }
  return null;
}

/// Seeds IndexedDB as the app's key-value store does, with what sign-in
/// would have fetched.
const _seedScript = r'''
async (seed) => {
  const db = await new Promise((res, rej) => {
    const r = indexedDB.open('app_kv_store', 1);
    r.onupgradeneeded = () => r.result.createObjectStore('entries');
    r.onsuccess = () => res(r.result);
    r.onerror = () => rej(r.error);
  });
  await new Promise((res, rej) => {
    const tx = db.transaction('entries', 'readwrite');
    for (const [k, v] of Object.entries(seed)) tx.objectStore('entries').put(v, k);
    tx.oncomplete = res;
    tx.onerror = () => rej(tx.error);
  });
  db.close();
  return true;
}''';

/// Takes the screenshots in [scheme], `light` or `dark`, into [shotsDir].
Future<void> takeScreenshots(
  Browser browser,
  FakeTakeout takeout,
  String scheme,
) async {
  final dir = Directory(shotsDir(scheme));
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);

  final context = await browser.createIncognitoBrowserContext();
  final page = await context.newPage();
  await page.setViewport(
    const DeviceViewport(width: 390, height: 844, deviceScaleFactor: 2),
  );
  // Not MediaFeature.prefersColorsScheme: it names the feature
  // `prefers-colors-scheme`, which Chrome ignores.
  await page.devTools.client.send('Emulation.setEmulatedMedia', {
    'features': [
      {'name': 'prefers-color-scheme', 'value': scheme},
    ],
  });
  await page.emulateTimezone('America/Chicago');
  // A service worker would fetch pictures past the interception below.
  await page.devTools.network.setBypassServiceWorker(true);
  // Answer the app's requests for thumbnails and channel pictures with the
  // drawn ones.
  await page.setRequestInterception(true);
  page.onRequest.listen((request) {
    final picture = _pictureFor(request.url);
    if (picture == null) {
      request.continueRequest();
    } else if (!File(picture).existsSync()) {
      request.respond(status: 404);
    } else {
      request.respond(
        contentType: 'image/png',
        headers: {'access-control-allow-origin': '*'},
        body: File(picture).readAsBytesSync(),
      );
    }
  });

  Future<void> wait(int ms) => Future.delayed(Duration(milliseconds: ms));
  Future<void> tap(num x, num y, [int ms = 1500]) async {
    await page.mouse.click(Point(x, y));
    await wait(ms);
  }

  Future<void> shot(String name) async {
    await page.mouse.move(const Point(389, 843)); // off anything that hovers
    await wait(700);
    File('${dir.path}/$name.png').writeAsBytesSync(await page.screenshot());
    log('$scheme: $name');
  }

  await page.goto('$app/favicon.png');
  await page.evaluate<bool>(_seedScript, args: [takeout.seed]);
  await page.goto('$app/');
  await wait(6000);

  // Import.
  final chooser = page.waitForFileChooser();
  await wait(200);
  await tap(195, 548, 0); // Select zip files
  await (await chooser).accept([File('$work/$takeoutFileName')]);
  await wait(5000);
  await shot('channels');

  await tap(200, 247, 3000); // Byte Sized Builds
  await shot('channel');

  await tap(28, 28, 2000);
  await tap(200, 191, 3000); // Speedrun Saturdays
  await tap(292, 79, 2500); // Live Chats tab
  await shot('super-chats');

  await tap(28, 28, 2000);
  await tap(180, 91, 500);
  await page.keyboard.type('first', delay: const Duration(milliseconds: 60));
  await wait(2500);
  await shot('search');

  // Queue every match, from the dialog.
  await tap(352, 147);
  await tap(290, 612, 6000); // Queue 8

  // Clear the search and select three comments on one channel.
  await tap(305, 91);
  await tap(200, 247, 3000); // Byte Sized Builds
  await tap(302, 80, 1200); // Select
  await tap(220, 303, 300);
  await tap(220, 368, 300);
  await tap(220, 548, 500);
  await shot('select');
  await tap(286, 811, 6000); // Queue 3
  await tap(28, 28, 2500); // back to the channel list

  await tap(273, 28, 2000); // Deletion queue
  await shot('queue');
  await tap(113, 811, 2000); // Delete 11…
  await shot('delete');
  await page.keyboard.press(Key.escape);
  await wait(1200);
  await tap(365, 28, 2000); // close the queue

  await tap(313, 28, 4000); // History
  await shot('history');
  await tap(28, 28, 2500);

  await tap(358, 28, 2500); // Takeouts
  await shot('takeouts');

  await context.close();
}
