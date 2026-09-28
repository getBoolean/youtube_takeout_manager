// Regenerates every README screenshot: node tool/screenshots/run.mjs
import { execFileSync } from 'node:child_process';
import path from 'node:path';

import { TOOL } from './common.mjs';

const step = (script, ...args) =>
  execFileSync(process.execPath, [path.join(TOOL, script), ...args], { stdio: 'inherit' });

step('gen.mjs');
step('render.mjs');
step('shoot.mjs', 'light');
step('shoot.mjs', 'dark');
step('compose.mjs');
