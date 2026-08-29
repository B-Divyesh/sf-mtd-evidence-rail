import { chromium } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import { readFile } from 'node:fs/promises';

const base = 'https://mtd-evidence-rail.sociobot.in';
const report = { generated_at: new Date().toISOString(), base, routes: {}, core_flow: {}, ui_flow: {}, reduced_motion: {}, mobile: {} };
const browser = await chromium.launch({ headless: true });

try {
  const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const page = await context.newPage();
  const requests = [];
  const errors = [];
  page.on('request', request => requests.push({ method: request.method(), url: request.url(), type: request.resourceType() }));
  page.on('console', message => { if (message.type() === 'error') errors.push(`console: ${message.text()}`); });
  page.on('pageerror', error => errors.push(`pageerror: ${error.message}`));
  const landingResponse = await page.goto(base, { waitUntil: 'networkidle' });
  await page.screenshot({ path: '.factory/evidence/verification-5/desktop-live.png', fullPage: true });
  await page.keyboard.press('Tab');
  const skipFocused = await page.getByRole('link', { name: 'Skip to main content' }).evaluate(el => el === document.activeElement);
  const focusStyle = await page.getByRole('link', { name: 'Skip to main content' }).evaluate(el => {
    const s = getComputedStyle(el);
    return { outline: s.outline, outlineOffset: s.outlineOffset, boxShadow: s.boxShadow };
  });
  const firstRead = {
    title: await page.title(), lang: await page.locator('html').getAttribute('lang'), h1: await page.locator('h1').allTextContents(),
    main_count: await page.locator('main').count(), primary: await page.getByRole('link', { name: 'Try it with sample data' }).innerText(),
    primary_box: await page.getByRole('link', { name: 'Try it with sample data' }).boundingBox(), skipFocused, focusStyle,
    headers: landingResponse?.headers(),
  };
  await page.getByRole('link', { name: 'Try it with sample data' }).focus();
  await page.keyboard.press('Enter');
  await page.getByText('Community hall hire').waitFor();
  const apiResponse = await page.waitForResponse(r => r.url().includes('/api/workspace') && r.status() === 200, { timeout: 5000 }).catch(() => null);
  await page.getByRole('button', { name: 'Show missing evidence' }).click();
  await page.getByText('2 shown').waitFor();
  await page.screenshot({ path: '.factory/evidence/verification-5/demo-desktop-live.png', fullPage: true });
  report.core_flow = {
    firstRead,
    demo_url: page.url(),
    banner: await page.getByRole('complementary', { name: 'Demo controls' }).innerText(),
    missing_count: await page.locator('.records .record').count(),
    request_count: requests.length,
    request_origins: [...new Set(requests.map(r => new URL(r.url).origin))],
    requests,
    api_headers: apiResponse?.headers() || null,
    errors,
  };

  for (const path of ['/', '/demo', '/app', '/privacy', '/terms', '/not-a-page']) {
    const response = await page.goto(base + path, { waitUntil: 'networkidle' });
    if (path === '/demo') await page.getByText('Community hall hire').waitFor();
    const axe = await new AxeBuilder({ page }).analyze();
    report.routes[path] = {
      status: response?.status(), title: await page.title(), h1_count: await page.locator('h1').count(),
      h1: await page.locator('h1').allTextContents(), main_count: await page.locator('main').count(),
      axe: axe.violations.map(v => ({ id: v.id, impact: v.impact, nodes: v.nodes.length })),
    };
  }
  await context.close();

  const uiContext = await browser.newContext({ viewport: { width: 1440, height: 900 }, acceptDownloads: true });
  const ui = await uiContext.newPage();
  const uiErrors = [];
  ui.on('pageerror', error => uiErrors.push(`pageerror: ${error.message}`));
  await ui.goto(base + '/app');
  await ui.getByText('No transactions in this quarter').waitFor();
  const workspaceKey = await ui.evaluate(() => localStorage.getItem('mtd-evidence-rail:workspace'));
  await ui.locator('#quarter').selectOption('2026-2');
  await ui.getByRole('button', { name: 'Add a transaction' }).click();
  const dialogInitialFocus = await ui.locator('#kind').evaluate(el => el === document.activeElement);
  await ui.locator('#record-date').fill('2026-10-05');
  await ui.locator('#description').fill('Quarter-end boundary expense');
  await ui.locator('#amount').fill('0');
  await ui.locator('#category').fill('Travel');
  await ui.getByRole('button', { name: 'Save transaction' }).click();
  const zeroError = await ui.locator('#form-error').innerText();
  const errorLive = await ui.locator('#form-error').getAttribute('aria-live');
  await ui.locator('#amount').fill('0.01');
  await ui.getByRole('button', { name: 'Save transaction' }).click();
  await ui.getByText('Transaction saved. Link its evidence when you have it.').waitFor();
  const savedVisible = await ui.getByText('Quarter-end boundary expense').isVisible();
  const evidenceInput = ui.locator('.record', { hasText: 'Quarter-end boundary expense' }).locator('input[type=file]');
  await evidenceInput.setInputFiles({ name: 'unsafe.exe', mimeType: 'application/octet-stream', buffer: Buffer.from('no') });
  await ui.getByText('Choose a PDF, JPG, PNG, WebP, or text file.').waitFor();
  const unsupportedError = await ui.getByText('Choose a PDF, JPG, PNG, WebP, or text file.').innerText();
  await evidenceInput.setInputFiles({ name: 'receipt.txt', mimeType: 'text/plain', buffer: Buffer.from('Train receipt') });
  await ui.getByText('receipt.txt is linked.').waitFor();
  await ui.getByRole('button', { name: 'Import bank CSV' }).click();
  await ui.locator('#csv-file').setInputFiles({ name: 'bad.csv', mimeType: 'text/csv', buffer: Buffer.from('When,What,Value\n2026-10-04,Bad headings,-2.00\n') });
  await ui.getByText('The CSV needs Date, Description, and Amount columns. Rename those headings and try again.').waitFor();
  const csvError = await ui.getByText('The CSV needs Date, Description, and Amount columns. Rename those headings and try again.').innerText();
  await ui.locator('#csv-file').setInputFiles({ name: 'good.csv', mimeType: 'text/csv', buffer: Buffer.from('Date,Description,Amount,Category\n04/10/2026,Printer paper,-10.50,Office\n') });
  await ui.getByText('1 rows read.').waitFor();
  await ui.getByRole('button', { name: 'Import new transactions' }).click();
  await ui.getByText('1 bank transaction imported.').waitFor();
  const downloadPromise = ui.waitForEvent('download');
  await ui.getByRole('button', { name: 'Export evidence pack' }).click();
  const download = await downloadPromise;
  const downloadPath = await download.path();
  const downloadBytes = await readFile(downloadPath);
  await ui.screenshot({ path: '.factory/evidence/verification-5/private-workspace-live.png', fullPage: true });
  ui.once('dialog', dialog => dialog.accept());
  await ui.getByRole('button', { name: 'Workspace settings' }).click();
  await ui.getByRole('button', { name: 'Delete all workspace data' }).click();
  await ui.waitForURL(base + '/');
  const cleared = await ui.evaluate(() => localStorage.getItem('mtd-evidence-rail:workspace'));
  const deletedResponse = await ui.request.get(base + '/api/workspace', { headers: { 'X-Workspace-Key': workspaceKey } });
  report.ui_flow = {
    workspace_key_length: workspaceKey?.length, dialogInitialFocus, zeroError, errorLive, savedVisible, unsupportedError, csvError,
    importedVisible: await ui.getByText('Link each expense to evidence').isVisible(),
    export_name: download.suggestedFilename(), export_zip_signature: downloadBytes.subarray(0, 2).toString(),
    workspace_key_after_delete: cleared, deleted_status: deletedResponse.status(), errors: uiErrors,
  };
  await uiContext.close();

  const mobileContext = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const mobile = await mobileContext.newPage();
  await mobile.goto(base, { waitUntil: 'networkidle' });
  await mobile.screenshot({ path: '.factory/evidence/verification-5/mobile-live.png', fullPage: true });
  const mobilePrimary = await mobile.getByRole('link', { name: 'Try it with sample data' }).boundingBox();
  const mobileGeometry = await mobile.evaluate(() => ({ clientWidth: document.documentElement.clientWidth, scrollWidth: document.documentElement.scrollWidth, innerWidth, innerHeight }));
  await mobile.getByRole('link', { name: 'Try it with sample data' }).click();
  await mobile.getByText('Community hall hire').waitFor();
  await mobile.getByRole('button', { name: 'Add a transaction' }).click();
  const dialogFits = await mobile.locator('#record-dialog').evaluate(el => { const r = el.getBoundingClientRect(); return { left: r.left, right: r.right, width: r.width, viewport: innerWidth }; });
  await mobile.keyboard.press('Escape');
  report.mobile = { primary_box: mobilePrimary, primary_above_fold: mobilePrimary ? mobilePrimary.y + mobilePrimary.height <= 844 : false, geometry: mobileGeometry, dialogFits };
  await mobileContext.close();

  const reducedContext = await browser.newContext({ reducedMotion: 'reduce', viewport: { width: 390, height: 844 } });
  const reduced = await reducedContext.newPage();
  await reduced.goto(base);
  report.reduced_motion = await reduced.evaluate(() => {
    const marker = document.querySelector('.train-marker');
    const style = marker ? getComputedStyle(marker) : null;
    return { media_matches: matchMedia('(prefers-reduced-motion: reduce)').matches, animationName: style?.animationName, transitionDuration: style?.transitionDuration, scrollBehavior: getComputedStyle(document.documentElement).scrollBehavior };
  });
  await reducedContext.close();
} finally {
  await browser.close();
}

console.log(JSON.stringify(report, null, 2));
