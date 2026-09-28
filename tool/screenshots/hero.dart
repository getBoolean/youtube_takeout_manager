// Frames three screenshots, labelled, into the README's hero in a light and
// a dark version, and copies the light screenshots next to it for the
// README's "More screenshots" grid.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart';

import 'common.dart';
import 'shoot.dart';

const _screens = [
  ('channel', 'Browse every comment'),
  ('search', 'Search every channel'),
  ('queue', 'Bulk delete, no daily limit'),
];

typedef _Theme = ({
  String background,
  String bezel,
  String shadow,
  String label,
  String pill,
  String number,
});

const _themes = <String, _Theme>{
  'light': (
    background:
        'radial-gradient(120% 90% at 50% 0%, #fff7f5 0%, #fde6df 60%, #f8d6cc 100%)',
    bezel: '#1d1b1e',
    shadow:
        '0 28px 56px rgba(110, 30, 20, .22), 0 6px 14px rgba(110, 30, 20, .12)',
    label: '#2b1714',
    pill: 'rgba(255, 255, 255, .72)',
    number: '#c62828',
  ),
  'dark': (
    background:
        'radial-gradient(120% 90% at 50% 0%, #3a1f1b 0%, #231514 55%, #181010 100%)',
    bezel: '#3a3436',
    shadow: '0 28px 56px rgba(0, 0, 0, .55), 0 6px 14px rgba(0, 0, 0, .35)',
    label: '#fbe9e5',
    pill: 'rgba(255, 255, 255, .08)',
    number: '#ff6b5e',
  ),
};

String _page(String scheme, _Theme t) =>
    '''
<!doctype html><html><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Roboto:wght@500;700&display=block" rel="stylesheet">
<style>
  * { box-sizing: border-box; }
  body { margin: 0; background: transparent; }
  #hero { width: 1080px; height: 772px; background: ${t.background}; display: flex; justify-content: center; align-items: flex-start;
          gap: 44px; padding: 34px 0 0; border-radius: 28px; font-family: Roboto, sans-serif; }
  .col { display: flex; flex-direction: column; align-items: center; gap: 18px; }
  .label { display: flex; align-items: center; gap: 10px; padding: 7px 16px 7px 8px; border-radius: 999px; background: ${t.pill};
           color: ${t.label}; font-weight: 700; font-size: 19px; letter-spacing: .1px; }
  .num { width: 26px; height: 26px; border-radius: 50%; background: ${t.number}; color: #fff; display: grid; place-items: center; font-size: 15px; }
  .phone { width: 306px; padding: 8px; border-radius: 42px; background: ${t.bezel}; box-shadow: ${t.shadow}; }
  .phone img { display: block; width: 100%; border-radius: 34px; }
</style></head><body><div id="hero">
${[for (final (i, (screen, label)) in _screens.indexed) '''
  <div class="col">
    <div class="label"><span class="num">${i + 1}</span>$label</div>
    <div class="phone"><img src="${fileUrl('${shotsDir(scheme)}/$screen.png')}"></div>
  </div>'''].join()}
</div></body></html>''';

/// Writes `hero-light.png` and `hero-dark.png` into [images], and the light
/// screenshots beside them.
Future<void> composeHeroes(Browser browser) async {
  final page = await browser.newPage();
  await page.setViewport(
    const DeviceViewport(width: 1080, height: 772, deviceScaleFactor: 2),
  );
  for (final MapEntry(key: scheme, value: theme) in _themes.entries) {
    final html = File('$work/hero-$scheme.html')
      ..writeAsStringSync(_page(scheme, theme));
    await page.goto(fileUrl(html.path), wait: Until.networkIdle);
    await page.evaluate<bool>('() => document.fonts.ready.then(() => true)');
    final hero = await page.$('#hero');
    File(
      '$images/hero-$scheme.png',
    ).writeAsBytesSync(await hero.screenshot(omitBackground: true));
    log('composed hero-$scheme.png');
  }
  await page.close();

  for (final shot in Directory(
    shotsDir('light'),
  ).listSync().whereType<File>()) {
    shot.copySync('$images/${p.basename(shot.path)}');
  }
}
