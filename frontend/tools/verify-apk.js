#!/usr/bin/env node
/**
 * Checks that a built APK really carries the values from `dart_defines.json`.
 *
 *   node tools/verify-apk.js
 *
 * `--dart-define-from-file` once produced an APK with no defines at all and
 * said nothing about it: the app installed, opened, and then failed on its
 * first request with a generic error. Reading the values back out of the
 * binary is the only way to know before shipping it to someone.
 */
const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const root = path.join(__dirname, '..');
const defines = JSON.parse(fs.readFileSync(path.join(root, 'dart_defines.json'), 'utf8'));
const apkDir = path.join(root, 'build', 'app', 'outputs', 'flutter-apk');

const apks = fs.existsSync(apkDir)
  ? fs.readdirSync(apkDir).filter((f) => f.endsWith('.apk'))
  : [];
if (apks.length === 0) {
  console.error('No APK found. Build one first: node tools/build-apk.js');
  process.exit(1);
}

// Values worth proving reached the binary. Firebase ids only matter when push
// is on; an empty value is nothing to look for.
const expected = ['API_BASE_URL', ...(defines.ENABLE_PUSH ? ['FIREBASE_PROJECT_ID'] : [])]
  .map((key) => [key, defines[key]])
  .filter(([, value]) => typeof value === 'string' && value.length > 0);

let failed = false;

for (const apk of apks) {
  const out = fs.mkdtempSync(path.join(os.tmpdir(), 'medaid-apk-'));
  try {
    execFileSync('unzip', ['-o', '-q', path.join(apkDir, apk), 'lib/*/libapp.so', '-d', out]);
    const libDir = path.join(out, 'lib');
    const abis = fs.existsSync(libDir) ? fs.readdirSync(libDir) : [];
    if (abis.length === 0) {
      console.log(`${apk}: no libapp.so found — cannot verify`);
      failed = true;
      continue;
    }
    console.log(`\n${apk}`);
    for (const abi of abis) {
      const so = path.join(libDir, abi, 'libapp.so');
      const blob = fs.readFileSync(so).toString('latin1');
      for (const [key, value] of expected) {
        const present = blob.includes(value);
        if (!present) failed = true;
        console.log(`  ${abi.padEnd(12)} ${key.padEnd(20)} ${present ? 'present' : 'MISSING'}`);
      }
    }
  } finally {
    fs.rmSync(out, { recursive: true, force: true });
  }
}

if (failed) {
  console.error(
    '\nAt least one value never reached the binary. Do not ship this APK: the app ' +
      'will fail on its first request with a generic error.',
  );
  process.exit(1);
}
console.log('\nAll expected values are compiled in.');
