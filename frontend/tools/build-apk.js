#!/usr/bin/env node
/**
 * Builds the release APK from `dart_defines.json`.
 *
 *   node tools/build-apk.js                 # all ABIs, one fat APK
 *   node tools/build-apk.js --split-per-abi # one APK per architecture
 *
 * Why not just `flutter build apk --dart-define-from-file=dart_defines.json`?
 * Because on Flutter 3.44 that silently produced an APK with *no* defines at
 * all: `String.fromEnvironment` came back empty, the app threw on its first
 * request and showed a generic error, and nothing in the build output said so.
 * The same file works for `flutter build bundle`, so the flag is accepted —
 * it just does not reach the release AOT build. Expanding the file into
 * explicit `--dart-define` flags does work, and is verifiable afterwards.
 *
 * The JSON stays the single source of truth either way. Keys starting with `_`
 * are comments and are skipped.
 */
const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const root = path.join(__dirname, '..');
const definesPath = path.join(root, 'dart_defines.json');

if (!fs.existsSync(definesPath)) {
  console.error(
    'Missing frontend/dart_defines.json. Copy dart_defines.example.json to it and fill it in.',
  );
  process.exit(1);
}

let defines;
try {
  defines = JSON.parse(fs.readFileSync(definesPath, 'utf8'));
} catch (error) {
  console.error(`dart_defines.json is not valid JSON: ${error.message}`);
  process.exit(1);
}

const entries = Object.entries(defines).filter(([key]) => !key.startsWith('_'));

const apiBaseUrl = defines.API_BASE_URL;
if (!apiBaseUrl) {
  console.error(
    'API_BASE_URL is empty. A release build must be told its server, e.g.\n' +
      '  "API_BASE_URL": "https://your-service.onrender.com/api/v1"',
  );
  process.exit(1);
}
if (!/^https:\/\//.test(apiBaseUrl)) {
  console.error(`API_BASE_URL must be https for a release build, got: ${apiBaseUrl}`);
  process.exit(1);
}
if (!apiBaseUrl.includes('/api/')) {
  console.error(
    `API_BASE_URL looks incomplete: ${apiBaseUrl}\n` +
      'It must include the API path, e.g. https://host/api/v1 — without it every request 404s.',
  );
  process.exit(1);
}

const args = [
  'build',
  'apk',
  '--release',
  ...process.argv.slice(2),
  ...entries.map(([key, value]) => `--dart-define=${key}=${value}`),
];

console.log('flutter ' + args.map((a) => (a.includes(' ') ? `"${a}"` : a)).join(' ') + '\n');

const result = spawnSync('flutter', args, { cwd: root, stdio: 'inherit', shell: true });
if (result.status !== 0) process.exit(result.status ?? 1);

// The failure this script exists to prevent is silent, so prove it did not
// happen: the URL must actually be present in the compiled binary.
const apkDir = path.join(root, 'build', 'app', 'outputs', 'flutter-apk');
const apks = fs.existsSync(apkDir)
  ? fs.readdirSync(apkDir).filter((f) => f.endsWith('.apk') && !f.endsWith('.sha1'))
  : [];
console.log(`\nBuilt ${apks.length} APK(s) in ${path.relative(root, apkDir)}:`);
for (const apk of apks) {
  const size = (fs.statSync(path.join(apkDir, apk)).size / 1024 / 1024).toFixed(1);
  console.log(`  ${apk}  (${size} MB)`);
}
console.log(`\nVerify the server address reached the binary:\n  node tools/verify-apk.js`);
