// Browser E2E for the web export (SPEC-06 AC-06-5): real clicks on the canvas only.
// Usage: node tools/e2e_web.js <url> <out_dir> [chromium_path]
// Needs a *debug* web export (main.gd publishes window.rbState) and `npm i playwright`.
const { chromium } = require('playwright');

const [url, outDir, exe] = process.argv.slice(2);
const SCALE = 450 / 720; // 450x800 viewport shows the 720x1280 game at 0.625
const START_BTN = [360, 747]; // title "게임 시작" (game coords)
// candidate build spots for stage 1, tried in order until one is valid
const SPOTS = [[360, 470], [300, 200], [500, 140], [200, 640], [520, 600], [360, 880]];

const results = [];
const check = (c, m) => { results.push(!!c); console.log(`${c ? 'PASS' : 'FAIL'} ${m}`); };

(async () => {
  const browser = await chromium.launch({
    executablePath: exe || undefined,
    args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'],
  });
  const page = await browser.newPage({ viewport: { width: 450, height: 800 } });
  const errors = [];
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('pageerror', e => errors.push(String(e)));

  const st = () => page.evaluate(() => window.rbState || null);
  const click = async ([x, y]) => { await page.mouse.move(x * SCALE, y * SCALE); await page.waitForTimeout(80); await page.mouse.click(x * SCALE, y * SCALE); await page.waitForTimeout(350); };
  const center = r => [r[0] + r[2] / 2, r[1] + r[3] / 2];
  const shot = n => page.screenshot({ path: `${outDir}/e2e_${n}.png` });
  const waitFor = async (pred, ms) => {
    const end = Date.now() + ms;
    while (Date.now() < end) { const s = await st(); if (s && pred(s)) return s; await page.waitForTimeout(200); }
    return st();
  };

  await page.goto(url);
  await page.waitForTimeout(8000);
  await shot('1_title');
  await click(START_BTN);
  let s = await waitFor(x => x.scene === 'main', 30000);
  check(s && s.scene === 'main', 'title start button opens the game');
  const t0 = Date.now();
  check(s.gold === 150 && s.life === 20, `start gold 150 / life 20 (got ${s.gold}/${s.life})`);

  // place a ballista (bar button 0) by tapping candidate spots
  await click(center(s.ui.bar[0]));
  s = await waitFor(x => x.placing, 2000);
  check(s.placing, 'tower bar button enters placement');
  for (const p of SPOTS) {
    await click(p);
    s = await st();
    if (s.towers.length > 0) break;
  }
  check(s.towers.length === 1 && s.towers[0].id === 'ballista', `placed ballista by tap (towers ${s.towers.length})`);
  check(s.gold === 50, `paid 100 (gold ${s.gold})`);
  const placedAt = (Date.now() - t0) / 1000;
  check(!s.in_wave, `player had time to build before wave 1 (placed after ${placedAt.toFixed(1)}s, in_wave=${s.in_wave})`);
  await shot('2_placed');

  // open inspector by tapping the tower
  const tp = s.towers[0].pos;
  await click(tp);
  s = await st();
  check(s.inspector && s.ui.upgrade.length === 4, 'tapping tower opens inspector');
  await shot('3_inspector');

  // with 50 gold the 70g upgrade must be refused (button disabled)
  await click(center(s.ui.upgrade));
  s = await st();
  check(s.towers[0].level === 0 && s.gold === 50, `upgrade refused without gold (level ${s.towers[0].level}, gold ${s.gold})`);

  // sell -> 70% of 100
  if (!s.inspector) { await click(tp); s = await st(); }
  const g2 = s.gold;
  await click(center(s.ui.sell));
  s = await st();
  check(s.towers.length === 0, 'sell removes tower');
  check(s.gold === g2 + 70, `refund 70% of 100 (${g2} -> ${s.gold})`);

  // rebuild + upgrade once affordable: place, then upgrade via inspector button
  await click(center(s.ui.bar[0]));
  for (const p of SPOTS) { await click(p); s = await st(); if (s.towers.length > 0) break; }
  check(s.towers.length === 1, 'rebuilt ballista');
  s = await waitFor(x => x.gold >= 70, 120000);
  const tp2 = s.towers[0].pos;
  if (s.gold >= 70) {
    await click(tp2); s = await st();
    const g = s.gold;
    await click(center(s.ui.upgrade));
    s = await st();
    check(s.towers[0].level === 1 && s.gold <= g - 70 + 12, `upgrade via button (level ${s.towers[0].level}, ${g} -> ${s.gold})`);
  } else {
    check(false, `could not earn 70 gold in 120s (gold ${s.gold}, wave ${s.wave}, life ${s.life}) - see balance`);
  }
  s = await waitFor(x => x.wave >= 2, 60000);
  check(s.wave >= 2, `waves progress (wave ${s.wave}, life ${s.life})`);
  await shot('4_progress');

  const real = errors.filter(e => !/AudioContext|audio/i.test(e));
  check(real.length === 0, `no console errors (${real.length})`);
  if (real.length) console.log(real.slice(0, 10).join('\n'));
  await browser.close();
  const fails = results.filter(r => !r).length;
  console.log(`\n==== ${results.length} checks, ${fails} failed ====`);
  process.exit(fails);
})().catch(e => { console.error(e); process.exit(99); });
