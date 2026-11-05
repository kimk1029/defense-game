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
  // Software-rendered CI browsers can run the game at ~2-5 FPS, so give every
  // input a few frames: move, settle, press, hold, release, settle.
  const click = async ([x, y]) => {
    if (!Number.isFinite(x) || !Number.isFinite(y)) throw new Error(`bad click target ${x},${y}`);
    await page.mouse.move(x * SCALE, y * SCALE); await page.waitForTimeout(400);
    await page.mouse.down(); await page.waitForTimeout(200); await page.mouse.up();
    await page.waitForTimeout(700);
  };
  const center = r => [r[0] + r[2] / 2, r[1] + r[3] / 2];
  const shot = n => page.screenshot({ path: `${outDir}/e2e_${n}.png` });
  const waitFor = async (pred, ms) => {
    const end = Date.now() + ms;
    while (Date.now() < end) { const s = await st(); if (s && pred(s)) return s; await page.waitForTimeout(200); }
    return st();
  };

  const placeTower = async (i) => {
    let cur = await st();
    const before = cur.towers.length;
    await click(center(cur.ui.bar[i]));
    await waitFor(x => x.placing, 8000);
    for (const p of SPOTS) {
      await click(p);
      cur = await waitFor(x => x.towers.length > before, 5000);
      if (cur.towers.length > before) break;
    }
    return cur;
  };

  await page.goto(url);
  await page.waitForTimeout(8000);
  await shot('1_title');
  await click(START_BTN);
  let s = await waitFor(x => x.scene === 'main', 30000);
  check(s && s.scene === 'main', 'title start button opens the game');
  const t0 = Date.now();
  check(s.gold === 250 && s.life === 20, `start gold 250 / life 20 (got ${s.gold}/${s.life})`);

  // place a ballista (bar button 0) by tapping candidate spots
  await click(center(s.ui.bar[0]));
  s = await waitFor(x => x.placing, 8000);
  check(s.placing, 'tower bar button enters placement');
  await click([80, 80]); // on the path (stage 1 start): invalid, stays in placement
  s = await st();
  check(s.placing && s.towers.length === 0, `tap on path is rejected (towers ${s.towers.length})`);
  s = await placeTower(0);
  check(s.towers.length === 1 && s.towers[0].id === 'ballista', `placed ballista by tap (towers ${s.towers.length})`);
  check(s.gold === 150, `paid 100 (gold ${s.gold})`);
  s = await placeTower(0);
  check(s.towers.length === 2 && s.gold === 50, `second ballista (towers ${s.towers.length}, gold ${s.gold})`);
  const placedAt = (Date.now() - t0) / 1000;
  check(!s.in_wave, `player had time to build before wave 1 (placed after ${placedAt.toFixed(1)}s, in_wave=${s.in_wave})`);
  await shot('2_placed');

  // open inspector by tapping the first tower
  const tp = s.towers[0].pos;
  await click(tp);
  s = await waitFor(x => x.inspector && x.ui.upgrade.length === 4, 8000);
  check(s.inspector, 'tapping tower opens inspector');
  if (!s.inspector) throw new Error('inspector did not open; aborting dependent steps');
  await shot('3_inspector');

  // with 50 gold the 70g upgrade must be refused (button disabled)
  await click(center(s.ui.upgrade));
  await page.waitForTimeout(2500);
  s = await st();
  check(s.towers[0].level === 0 && s.gold === 50, `upgrade refused without gold (level ${s.towers[0].level}, gold ${s.gold})`);

  // sell -> 70% of 100
  if (!s.inspector) { await click(tp); s = await waitFor(x => x.inspector, 8000); }
  const g2 = s.gold;
  await click(center(s.ui.sell));
  s = await waitFor(x => x.towers.length === 1, 8000);
  check(s.towers.length === 1, 'sell removes tower');
  check(s.gold >= g2 + 70, `refund 70% of 100 (${g2} -> ${s.gold})`);

  // upgrade the remaining tower via the inspector button once 70g is available
  s = await waitFor(x => x.gold >= 70, 240000);
  check(s.gold >= 70, `gold available for upgrade (gold ${s.gold}, wave ${s.wave}, life ${s.life})`);
  const tp2 = s.towers[0].pos;
  await click(tp2);
  s = await waitFor(x => x.inspector, 8000);
  const g = s.gold;
  await click(center(s.ui.upgrade));
  s = await waitFor(x => x.towers[0].level === 1, 8000);
  check(s.towers[0].level === 1 && s.gold <= g - 70 + 12, `upgrade via button (level ${s.towers[0].level}, ${g} -> ${s.gold})`);
  s = await waitFor(x => x.wave >= 2, 120000);
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
