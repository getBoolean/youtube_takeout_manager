// Paths and helpers the screenshot scripts share.
import { execSync } from 'node:child_process';
import fs from 'node:fs';
import http from 'node:http';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const TOOL = path.dirname(fileURLToPath(import.meta.url));
export const REPO = path.resolve(TOOL, '..', '..');

/** The generated takeout, pictures and raw screenshots, ignored with the rest of build/. */
export const WORK = path.join(REPO, 'build', 'screenshots');

/** The images the README shows. */
export const IMAGES = path.join(TOOL, 'images');

/** Playwright, installed globally: `npm i -g playwright`. */
export const { chromium } = createRequire(path.join(execSync('npm root -g').toString().trim(), 'noop.js'))('playwright');

/** Where the web build is served: the origin registered for web sign-in. */
export const APP = 'http://localhost:9000';

const TYPES = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json',
  '.wasm': 'application/wasm', '.png': 'image/png', '.otf': 'font/otf', '.ttf': 'font/ttf', '.css': 'text/css',
};

/** Serves build/web on [APP], sending unknown paths to index.html. Resolves to the server, to close. */
export function serveWebBuild() {
  const root = path.join(REPO, 'build', 'web');
  if (!fs.existsSync(path.join(root, 'index.html'))) {
    throw new Error('No web build: run `flutter build web --dart-define-from-file=.env` first.');
  }
  const server = http.createServer((req, res) => {
    let file = path.join(root, decodeURIComponent(new URL(req.url, APP).pathname));
    if (!file.startsWith(root) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
      file = path.join(root, 'index.html');
    }
    res.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] ?? 'application/octet-stream', 'Cache-Control': 'no-store' });
    fs.createReadStream(file).pipe(res);
  });
  return new Promise((resolve) => server.listen(new URL(APP).port, () => resolve(server)));
}
