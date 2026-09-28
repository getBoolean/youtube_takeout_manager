// Composes the README hero, three phone screenshots in frames, labelled, in
// a light and a dark version, and copies the light screenshots next to it.
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

import { chromium, IMAGES as OUT, WORK } from './common.mjs';

const screens = [
  ['channel', 'Browse every comment'],
  ['search', 'Search every channel'],
  ['queue', 'Bulk delete, no daily limit'],
];

const themes = {
  light: {
    dir: 'light', bg: 'radial-gradient(120% 90% at 50% 0%, #fff7f5 0%, #fde6df 60%, #f8d6cc 100%)',
    bezel: '#1d1b1e', shadow: '0 28px 56px rgba(110, 30, 20, .22), 0 6px 14px rgba(110, 30, 20, .12)',
    label: '#2b1714', pill: 'rgba(255, 255, 255, .72)', num: '#c62828',
  },
  dark: {
    dir: 'dark', bg: 'radial-gradient(120% 90% at 50% 0%, #3a1f1b 0%, #231514 55%, #181010 100%)',
    bezel: '#3a3436', shadow: '0 28px 56px rgba(0, 0, 0, .55), 0 6px 14px rgba(0, 0, 0, .35)',
    label: '#fbe9e5', pill: 'rgba(255, 255, 255, .08)', num: '#ff6b5e',
  },
};

const page = (t) => `<!doctype html><html><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Roboto:wght@500;700&display=block" rel="stylesheet">
<style>
  * { box-sizing: border-box; }
  body { margin: 0; background: transparent; }
  #hero { width: 1080px; height: 772px; background: ${t.bg}; display: flex; justify-content: center; align-items: flex-start;
          gap: 44px; padding: 34px 0 0; border-radius: 28px; font-family: Roboto, sans-serif; }
  .col { display: flex; flex-direction: column; align-items: center; gap: 18px; }
  .label { display: flex; align-items: center; gap: 10px; padding: 7px 16px 7px 8px; border-radius: 999px; background: ${t.pill};
           color: ${t.label}; font-weight: 700; font-size: 19px; letter-spacing: .1px; }
  .num { width: 26px; height: 26px; border-radius: 50%; background: ${t.num}; color: #fff; display: grid; place-items: center; font-size: 15px; }
  .phone { width: 306px; padding: 8px; border-radius: 42px; background: ${t.bezel}; box-shadow: ${t.shadow}; }
  .phone img { display: block; width: 100%; border-radius: 34px; }
</style></head><body><div id="hero">
${screens.map(([file, label], i) => `
  <div class="col">
    <div class="label"><span class="num">${i + 1}</span>${label}</div>
    <div class="phone"><img src="${pathToFileURL(path.join(WORK, 'shots', t.dir, file + '.png')).href}"></div>
  </div>`).join('')}
</div></body></html>`;

const browser = await chromium.launch();
const tab = await browser.newPage({ viewport: { width: 1080, height: 772 }, deviceScaleFactor: 2 });
for (const [name, t] of Object.entries(themes)) {
  const file = path.join(WORK, `hero-${name}.html`);
  fs.writeFileSync(file, page(t));
  await tab.goto(pathToFileURL(file).href);
  await tab.evaluate(() => document.fonts.ready);
  await tab.waitForTimeout(500);
  await tab.locator('#hero').screenshot({ path: path.join(OUT, `hero-${name}.png`), omitBackground: true });
  console.log(`composed hero-${name}.png`);
}
await browser.close();

// The "More screenshots" grid shows the light ones.
for (const file of fs.readdirSync(path.join(WORK, 'shots', 'light'))) {
  fs.copyFileSync(path.join(WORK, 'shots', 'light', file), path.join(OUT, file));
}
