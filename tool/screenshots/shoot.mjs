// Imports the fictional takeout into a fresh phone-sized browser and takes
// the README screenshots, in the theme given: `node shoot.mjs light|dark`.
// Taps are at fixed spots on a 390x844 screen, so a layout change can move
// what they hit; compare the new screenshots before committing them.
import fs from 'node:fs';
import path from 'node:path';

import { APP, chromium, serveWebBuild, WORK } from './common.mjs';

const scheme = process.argv[2] ?? 'light';
const SHOTS = path.join(WORK, 'shots', scheme);
fs.rmSync(SHOTS, { recursive: true, force: true });
fs.mkdirSync(SHOTS, { recursive: true });
const cors = { 'Access-Control-Allow-Origin': '*', 'Content-Type': 'image/png' };

const server = await serveWebBuild();
const browser = await chromium.launch();
const context = await browser.newContext({
  viewport: { width: 390, height: 844 },
  deviceScaleFactor: 2,
  // A service worker would fetch the pictures past the routes below.
  serviceWorkers: 'block',
  colorScheme: scheme,
  timezoneId: 'America/Chicago',
});
// Serve the made-up thumbnails and channel pictures where the app asks
// YouTube for them.
await context.route(/^https:\/\/i\.ytimg\.com\/vi\//, (route) => {
  const id = route.request().url().match(/\/vi\/([^/]+)\//)[1];
  return route.fulfill({ path: path.join(WORK, 'img', 'thumbs', `${id}.png`), headers: cors }).catch(() => route.abort());
});
await context.route(/^https:\/\/yt3\.ggpht\.com\/ytc\//, (route) => {
  const id = route.request().url().match(/\/ytc\/([^=]+)=/)[1];
  return route.fulfill({ path: path.join(WORK, 'img', 'avatars', `${id}.png`), headers: cors }).catch(() => route.abort());
});

const page = await context.newPage();
const wait = (ms) => page.waitForTimeout(ms);
const tap = async (x, y, ms = 1500) => { await page.mouse.click(x, y); await wait(ms); };
const shot = async (name) => {
  await page.mouse.move(389, 843); // off anything with a hover state
  await wait(700);
  await page.screenshot({ path: path.join(SHOTS, `${name}.png`) });
  console.log(`${scheme}: ${name}`);
};

// Seed the video details and channel pictures that sign-in would fetch.
await page.goto(`${APP}/favicon.png`);
const seed = JSON.parse(fs.readFileSync(path.join(WORK, 'seed.json'), 'utf8'));
await page.evaluate(async (seed) => {
  const db = await new Promise((res, rej) => {
    const r = indexedDB.open('app_kv_store', 1);
    r.onupgradeneeded = () => r.result.createObjectStore('entries');
    r.onsuccess = () => res(r.result); r.onerror = () => rej(r.error);
  });
  await new Promise((res, rej) => {
    const tx = db.transaction('entries', 'readwrite');
    for (const [k, v] of Object.entries(seed)) tx.objectStore('entries').put(v, k);
    tx.oncomplete = res; tx.onerror = () => rej(tx.error);
  });
  db.close();
}, seed);

await page.goto(`${APP}/`);
await wait(6000);

// Import.
const [chooser] = await Promise.all([page.waitForEvent('filechooser'), page.mouse.click(195, 548)]);
await chooser.setFiles(path.join(WORK, 'takeout-20260927T180000Z-001.zip'));
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
await page.keyboard.type('first', { delay: 60 });
await wait(2500);
await shot('search');

// Queue every match, from the dialog.
await tap(352, 147, 1500);
await tap(290, 612, 6000); // Queue 8

// Clear the search and select three comments on one channel.
await tap(305, 91, 1500);
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
await page.keyboard.press('Escape');
await wait(1200);
await tap(365, 28, 2000); // close the queue

await tap(313, 28, 4000); // History
await shot('history');
await tap(28, 28, 2500);

await tap(358, 28, 2500); // Takeouts
await shot('takeouts');

await browser.close();
server.close();
