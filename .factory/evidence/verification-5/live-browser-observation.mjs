import { chromium } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

const base = 'https://mtd-evidence-rail.sociobot.in';
const browser = await chromium.launch({ headless: true });
const out = { base, generated_at: new Date().toISOString() };

try {
  const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const page = await context.newPage();
  const requests = [];
  const responses = [];
  const errors = [];
  page.on('request', r => requests.push({ method: r.method(), url: r.url(), type: r.resourceType() }));
  page.on('response', r => { if (r.url().includes('/api/')) responses.push({ method: r.request().method(), status: r.status(), url: r.url(), retryAfter: r.headers()['retry-after'] || null }); });
  page.on('console', m => { if (m.type() === 'error') errors.push(`console: ${m.text()}`); });
  page.on('pageerror', e => errors.push(`pageerror: ${e.message}`));
  const documentResponse = await page.goto(base, { waitUntil: 'networkidle' });
  await page.screenshot({ path: '.factory/evidence/verification-5/desktop-live.png', fullPage: true });
  await page.keyboard.press('Tab');
  const skip = page.getByRole('link', { name: 'Skip to main content' });
  out.landing = {
    status: documentResponse?.status(), headers: documentResponse?.headers(), title: await page.title(), lang: await page.locator('html').getAttribute('lang'),
    h1: await page.locator('h1').allTextContents(), h1Count: await page.locator('h1').count(), mainCount: await page.locator('main').count(),
    primaryText: await page.getByRole('link', { name: 'Try it with sample data' }).innerText(),
    primaryBox: await page.getByRole('link', { name: 'Try it with sample data' }).boundingBox(),
    skipFocused: await skip.evaluate(el => el === document.activeElement),
    focusStyle: await skip.evaluate(el => { const s = getComputedStyle(el); return { outline: s.outline, outlineOffset: s.outlineOffset, boxShadow: s.boxShadow }; }),
  };
  await page.getByRole('link', { name: 'Try it with sample data' }).focus();
  await page.keyboard.press('Enter');
  const attempts = [];
  for (let n = 1; n <= 6; n++) {
    await page.waitForTimeout(800);
    const ready = await page.getByText('Community hall hire').isVisible().catch(() => false);
    attempts.push({ n, ready, retryVisible: await page.getByRole('button', { name: 'Try again' }).isVisible().catch(() => false), body: (await page.locator('main').innerText()).slice(0, 500) });
    if (ready) break;
    const retry = page.getByRole('button', { name: 'Try again' });
    if (await retry.isVisible().catch(() => false)) await retry.click();
  }
  const loaded = await page.getByText('Community hall hire').isVisible().catch(() => false);
  if (loaded) {
    await page.getByRole('button', { name: 'Show missing evidence' }).click();
    await page.getByText('2 shown').waitFor();
    await page.screenshot({ path: '.factory/evidence/verification-5/demo-desktop-live.png', fullPage: true });
  }
  out.demo = {
    url: page.url(), loaded, attempts,
    bannerVisible: await page.getByRole('complementary', { name: 'Demo controls' }).isVisible().catch(() => false),
    apiResponses: responses,
  };
  out.network = { requests, origins: [...new Set(requests.map(r => new URL(r.url).origin))], errors };
  out.axe = {};
  for (const path of ['/', '/privacy', '/terms', '/not-a-page']) {
    const response = await page.goto(base + path, { waitUntil: 'networkidle' });
    const axe = await new AxeBuilder({ page }).analyze();
    out.axe[path] = { status: response?.status(), violations: axe.violations.map(v => ({ id: v.id, impact: v.impact, nodes: v.nodes.length })) };
  }
  await context.close();

  const mobileContext = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const mobile = await mobileContext.newPage();
  await mobile.goto(base, { waitUntil: 'networkidle' });
  await mobile.screenshot({ path: '.factory/evidence/verification-5/mobile-live.png', fullPage: true });
  const primary = await mobile.getByRole('link', { name: 'Try it with sample data' }).boundingBox();
  out.mobile = {
    primary, primaryAboveFold: primary ? primary.y + primary.height <= 844 : false,
    geometry: await mobile.evaluate(() => ({ innerWidth, innerHeight, clientWidth: document.documentElement.clientWidth, scrollWidth: document.documentElement.scrollWidth })),
  };
  await mobileContext.close();

  const reducedContext = await browser.newContext({ reducedMotion: 'reduce', viewport: { width: 390, height: 844 } });
  const reduced = await reducedContext.newPage();
  await reduced.goto(base);
  out.reducedMotion = await reduced.evaluate(() => {
    const s = getComputedStyle(document.querySelector('.train-marker'));
    return { mediaMatches: matchMedia('(prefers-reduced-motion: reduce)').matches, animationName: s.animationName, transitionDuration: s.transitionDuration, scrollBehavior: getComputedStyle(document.documentElement).scrollBehavior };
  });
  await reducedContext.close();
} finally {
  await browser.close();
}

console.log(JSON.stringify(out, null, 2));
