// Draws the made-up channels' pictures and video thumbnails, which the
// screenshots show where YouTube's would be.

import 'dart:io';

import 'package:puppeteer/puppeteer.dart';

import 'common.dart';
import 'takeout.dart';

const avatarsDir = '$work/img/avatars';
const thumbnailsDir = '$work/img/thumbnails';

String _escape(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;');

String _avatar(Avatar a) =>
    '''
  <div class="avatar" id="a-${a.channelId}" style="background:linear-gradient(135deg, ${a.colors[0]}, ${a.colors[1]})">
    <div class="ring"></div>
    <span class="${a.monogram ? 'mono' : 'emoji'}">${a.text}</span>
  </div>''';

String _thumbnail(Thumbnail t) {
  // Without a caption, only the emoji.
  final caption = t.caption;
  final variant = caption == null ? 2 : t.layout;
  final text = _escape(caption ?? '');
  final layout = switch (variant) {
    0 =>
      '<span class="temoji big right">${t.emoji}</span><span class="ttext left">$text</span>',
    1 =>
      '<span class="temoji big left">${t.emoji}</span><span class="ttext right">$text</span>',
    2 => '<span class="temoji huge center">${t.emoji}</span>',
    _ =>
      '<span class="temoji big right">${t.emoji}</span><span class="ttext left bottom">$text</span>',
  };
  return '''
  <div class="thumb v$variant" id="t-${t.videoId}" style="background:radial-gradient(circle at ${variant.isOdd ? '25%' : '75%'} 40%, ${t.colors[1]}, ${t.colors[0]} 70%)">
    <div class="stripes"></div>
    $layout
    ${t.live ? '<span class="live">● LIVE</span>' : ''}
  </div>''';
}

const _style = '''
  body { margin: 0; background: #fff; display: flex; flex-wrap: wrap; gap: 8px; padding: 8px; font-family: 'Segoe UI', sans-serif; }
  .avatar { width: 176px; height: 176px; position: relative; display: grid; place-items: center; overflow: hidden; }
  .ring { position: absolute; inset: 18px; border-radius: 50%; border: 6px solid rgba(255,255,255,.18); }
  .emoji { font-size: 92px; font-family: 'Segoe UI Emoji'; filter: drop-shadow(0 4px 6px rgba(0,0,0,.35)); }
  .mono { font-size: 72px; font-weight: 800; color: #fff; letter-spacing: -2px; text-shadow: 0 3px 8px rgba(0,0,0,.3); }
  .thumb { width: 320px; height: 180px; position: relative; overflow: hidden; }
  .stripes { position: absolute; inset: 0; background: repeating-linear-gradient(115deg, rgba(255,255,255,.07) 0 18px, transparent 18px 44px); }
  .temoji { position: absolute; font-family: 'Segoe UI Emoji'; filter: drop-shadow(0 6px 10px rgba(0,0,0,.45)); }
  .big { font-size: 96px; top: 34px; }
  .huge { font-size: 118px; top: 18px; left: 0; right: 0; text-align: center; }
  .temoji.right { right: 22px; } .temoji.left { left: 22px; }
  .ttext { position: absolute; top: 30px; width: 176px; font: 900 29px/1.04 'Arial Black', 'Segoe UI', sans-serif; color: #fff;
           -webkit-text-stroke: 1.5px rgba(0,0,0,.55); text-shadow: 0 4px 0 rgba(0,0,0,.35); }
  .ttext.left { left: 18px; } .ttext.right { right: 18px; text-align: right; }
  .ttext.bottom { top: auto; bottom: 20px; }
  .v3 .live { left: auto; right: 10px; }
  .live { position: absolute; left: 10px; bottom: 10px; background: #dc2626; color: #fff; font: 700 13px 'Segoe UI'; padding: 2px 8px; border-radius: 4px; }
''';

/// Draws every channel's picture and video's thumbnail into [avatarsDir] and
/// [thumbnailsDir], at twice the size the app shows them.
Future<void> drawPictures(Browser browser, FakeTakeout takeout) async {
  Directory(avatarsDir).createSync(recursive: true);
  Directory(thumbnailsDir).createSync(recursive: true);
  final page = await browser.newPage();
  await page.setViewport(
    const DeviceViewport(width: 1400, height: 900, deviceScaleFactor: 2),
  );
  await page.setContent('''
<!doctype html><html><head><meta charset="utf-8"><style>$_style</style></head><body>
${takeout.avatars.map(_avatar).join()}
${takeout.thumbnails.map(_thumbnail).join()}
</body></html>''');
  await page.evaluate<bool>('() => document.fonts.ready.then(() => true)');
  for (final a in takeout.avatars) {
    final picture = await page.$('[id="a-${a.channelId}"]');
    File(
      '$avatarsDir/${a.channelId}.png',
    ).writeAsBytesSync(await picture.screenshot());
  }
  for (final t in takeout.thumbnails) {
    final picture = await page.$('[id="t-${t.videoId}"]');
    File(
      '$thumbnailsDir/${t.videoId}.png',
    ).writeAsBytesSync(await picture.screenshot());
  }
  await page.close();
  log(
    'drew ${takeout.avatars.length} channel pictures, '
    '${takeout.thumbnails.length} thumbnails',
  );
}
