// Warung Rot: an entry for make.fun's roblox-brainrot-01 bounty (Node 22,
// standard library only). The game lives in this directory's Rojo project;
// `rojo build default.project.json --output game.rbxl` turns it into the
// place file. This program hands the entry in: it copies game.rbxl, src/,
// screenshots/ and PLAY.json from beside this file to /output and writes
// /output/dossier.json with the vendored make.fun library, which is what
// the judge reads. Directory copies run in sorted name order so the two
// grading runs write identical bytes.
//
// Every name under /output must start with a letter, a digit or _ and hold
// only letters, digits, . _ and -; the copy below drops every name that
// starts with a dot, at any depth, so a stray .gitkeep or .DS_Store can
// never fail the entry.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, existsSync, mkdirSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

// Create the output directory up front so the copies below never fail on a
// fresh container or a local out/ that does not exist yet.
mkdirSync(out, { recursive: true });

/**
 * Copy one directory tree into another, visiting entries in sorted name
 * order and skipping every name that starts with a dot. Sorting keeps the
 * run deterministic: two runs lay out the same bytes in the same order.
 */
function copyTreeSorted(from: string, to: string): void {
  mkdirSync(to, { recursive: true });
  for (const name of readdirSync(from).sort()) {
    if (name.startsWith('.')) continue;
    const source = join(from, name);
    const target = join(to, name);
    if (statSync(source).isDirectory()) {
      copyTreeSorted(source, target);
    } else {
      copyFileSync(source, target);
    }
  }
}

copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
copyTreeSorted(join(here, 'src'), join(out, 'src'));
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) copyTreeSorted(join(here, 'screenshots'), join(out, 'screenshots'));

// The scorer's own caps (reference/gate.json): only text_max_bytes shapes the bytes; the others refuse an entry the
// scorer would refuse (more than 4 screenshots or one over 256 KiB; a place of more than 500000 instances, whose
// scripts' sources come to over 8 MiB or whose scripts' paths come to over 1048576 characters, in all).
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, { text_max_bytes: 65536, screenshots: { max: 4, max_bytes: 262144 }, max_instances: 500000, scripts_max_source_bytes: 8388608, scripts_max_path_chars: 1048576 }),
);
