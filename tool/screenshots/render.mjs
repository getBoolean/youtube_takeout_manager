// Renders the fictional channels' pictures and video thumbnails to PNGs.
import fs from 'node:fs';
import path from 'node:path';

import { chromium, WORK as OUT } from './common.mjs';

const spec = JSON.parse(fs.readFileSync(path.join(OUT, 'images.json'), 'utf8'));
fs.mkdirSync(path.join(OUT, 'img', 'avatars'), { recursive: true });
fs.mkdirSync(path.join(OUT, 'img', 'thumbs'), { recursive: true });

const esc = (s = '') => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');
// Thumbnail captions, short the way real thumbnails are. Missing ones get
// the emoji-only layout.
const captions = {
  'I Built a Weather Station for $12': '$12 WEATHER STATION', 'Soldering for Absolute Beginners': 'SOLDERING 101',
  'Why Your 3D Prints Keep Warping': 'NO MORE WARPING', 'Reviving a Dead Handheld From 1998': 'IT LIVES!',
  'The $5 Microcontroller That Does Everything': '$5 MAGIC', 'Building a Tiny E-Ink Clock': 'TINY CLOCK',
  'The Science of the Perfect Crispy Potato': 'SO CRISPY', 'Sourdough Without the Stress': 'EASY SOURDOUGH',
  '5 Knife Skills That Change Everything': '5 KNIFE SKILLS', 'I Cooked Only With a Rice Cooker for a Week': 'RICE COOKER ONLY',
  'Forgotten Handhelds of the 90s': 'LOST 90s HANDHELDS', 'Why Old Game Cartridges Still Work': 'STILL WORKS?!',
  'The Strangest Controller Ever Made': 'WHY?!', 'How Big Is the Universe, Really?': 'HOW BIG?',
  'Every Mars Rover, Ranked': 'RANKED', 'World Record Attempts — Any% Marathon 🔴': 'WR ATTEMPTS',
  'Race Night: 4-Way Relay': 'RACE NIGHT', 'rainy night coding session ☔': 'RAINY NIGHT',
  'Solo Overnight on the Ridge Trail': 'SOLO OVERNIGHT', 'My Ultralight Pack Is Under 10 lb': 'UNDER 10 LB',
  'Why Every Border Looks the Way It Does': 'WHY BORDERS?', 'Tiny Islands With Huge Stories': 'TINY ISLANDS',
  'The Most Beautiful Equation, Visualized': 'MIND = BLOWN', 'Throwing a Tall Vase in One Take': 'ONE TAKE',
  "Glaze Mistakes I'll Never Make Again": 'GLAZE FAILS', 'Balcony Tomatoes: Full Season Timelapse': 'BALCONY HARVEST',
  'Driving Through Neon — Full Album': 'FULL ALBUM', 'Cat Discovers the Dishwasher': 'NEW ENEMY',
  'Weekly Nap Rankings': 'NAP RANKINGS', 'Making a Walnut Desk Organizer': 'WALNUT BUILD',
  'Hand Tools Only: Dovetail Box': 'NO POWER TOOLS', 'How This One Shot Was Filmed': 'ONE SHOT?',
  'Practical Effects Still Win': 'NO CGI',
};
const shortTitle = (t) => captions[t];

const avatar = (a) => `
  <div class="avatar" id="a-${a.id}" style="background:linear-gradient(135deg, ${a.colors[0]}, ${a.colors[1]})">
    <div class="ring"></div>
    ${a.monogram ? `<span class="mono">${a.emoji}</span>` : `<span class="emoji">${a.emoji}</span>`}
  </div>`;

const thumb = (t) => {
  if (!shortTitle(t.title)) t.variant = 2;
  const layouts = [
    `<span class="temoji big right">${t.emoji}</span><span class="ttext left">${esc(shortTitle(t.title))}</span>`,
    `<span class="temoji big left">${t.emoji}</span><span class="ttext right">${esc(shortTitle(t.title))}</span>`,
    `<span class="temoji huge center">${t.emoji}</span>`,
    `<span class="temoji big right">${t.emoji}</span><span class="ttext left bottom">${esc(shortTitle(t.title))}</span>`,
  ];
  return `
  <div class="thumb v${t.variant}" id="t-${t.id}" style="background:radial-gradient(circle at ${t.variant % 2 ? '25%' : '75%'} 40%, ${t.colors[1]}, ${t.colors[0]} 70%)">
    <div class="stripes"></div>
    ${layouts[t.variant]}
    ${t.live ? '<span class="live">● LIVE</span>' : ''}
  </div>`;
};

const html = `<!doctype html><html><head><meta charset="utf-8"><style>
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
</style></head><body>
${spec.avatars.map(avatar).join('')}
${spec.thumbs.map(thumb).join('')}
</body></html>`;

const browser = await chromium.launch();
const page = await browser.newPage({ deviceScaleFactor: 2, viewport: { width: 1400, height: 900 } });
await page.setContent(html);
await page.evaluate(() => document.fonts.ready);
for (const a of spec.avatars) {
  await page.locator(`[id="a-${a.id}"]`).screenshot({ path: path.join(OUT, 'img', 'avatars', `${a.id}.png`) });
}
for (const t of spec.thumbs) {
  await page.locator(`[id="t-${t.id}"]`).screenshot({ path: path.join(OUT, 'img', 'thumbs', `${t.id}.png`) });
}
await browser.close();
console.log(`rendered ${spec.avatars.length} avatars, ${spec.thumbs.length} thumbnails`);
