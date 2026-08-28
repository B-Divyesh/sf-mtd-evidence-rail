import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import { readFileSync } from 'node:fs';

test('@claim:demo-isolation demo uses a separate 24-hour workspace', async ({ page }) => {
  let expiry:number|undefined;
  page.on('response', async response => {
    if (response.url().endsWith('/api/demo') && response.request().method() === 'POST') expiry = (await response.json()).expires_in_hours;
  });
  await page.goto('/demo');
  await expect(page.getByText('Demo — sample data, nothing is saved to your workspace')).toBeVisible();
  await expect(page.getByText('6', { exact: true }).first()).toBeVisible();
  const firstKey = await page.evaluate(() => sessionStorage.getItem('demo:mtd-evidence-rail:workspace'));
  expect(firstKey).toMatch(/^demo:[a-f0-9]{64}$/);
  expect(await page.evaluate(() => localStorage.getItem('mtd-evidence-rail:workspace'))).toBeNull();
  expect(expiry).toBe(24);
  await page.getByRole('button', { name: 'Reset demo' }).click();
  await expect.poll(() => page.evaluate(() => sessionStorage.getItem('demo:mtd-evidence-rail:workspace'))).not.toBe(firstKey);
});

test('@claim:no-account starts without sign-in and keeps the key on this device', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('link', { name: 'Start a private workspace' }).click();
  await expect(page).toHaveURL(/\/app$/);
  await expect(page.getByRole('heading', { level: 1, name: 'Prepare your quarter record' })).toBeVisible();
  await expect(page.getByText('No transactions in this quarter')).toBeVisible();
  await expect.poll(() => page.evaluate(() => localStorage.getItem('mtd-evidence-rail:workspace'))).toMatch(/^[a-f0-9]{64}$/);
  expect(await page.evaluate(() => sessionStorage.getItem('demo:mtd-evidence-rail:workspace'))).toBeNull();
});

test('@claim:quarter-capture saves income and expenses in the dated quarter', async ({ page }) => {
  await page.goto('/app');
  const key = await page.evaluate(() => localStorage.getItem('mtd-evidence-rail:workspace'));
  for (const record of [
    { kind: 'income', description: 'Tutoring session', amount_pence: 5000, category: 'Tutoring' },
    { kind: 'expense', description: 'Train ticket', amount_pence: 1290, category: 'Travel' },
  ]) {
    const response = await page.request.post('/api/records', {
      headers: { 'X-Workspace-Key': key! },
      data: { ...record, record_date: '2026-05-10', source: 'manual' },
    });
    expect(response.status()).toBe(201);
  }
  await page.locator('#quarter').selectOption('2026-1');
  await expect(page.getByText('Tutoring session')).toBeVisible();
  await expect(page.getByText('Train ticket')).toBeVisible();
});

test('@claim:csv-matching bank CSV review flags likely matches', async ({ page }) => {
  await page.goto('/demo');
  await page.getByRole('button', { name: 'Import bank CSV' }).click();
  await page.locator('#csv-file').setInputFiles({
    name: 'bank.csv', mimeType: 'text/csv',
    buffer: Buffer.from('Date,Description,Amount,Category\n19/05/2026,Train to client session,-27.80,Travel\n20/05/2026,Printer paper,-10.50,Office\n'),
  });
  await expect(page.getByText('2 rows read.')).toBeVisible();
  await expect(page.getByText('1 likely match will be skipped.')).toBeVisible();
  await page.getByRole('button', { name: 'Import new transactions' }).click();
  await expect(page.getByText('1 bank transaction imported.')).toBeVisible();
  await expect(page.locator('.records strong', { hasText: 'Printer paper' })).toBeVisible();
});

test('@claim:evidence-pack exports a ZIP with CSV and linked files', async ({ page }) => {
  await page.goto('/demo');
  const downloadPromise = page.waitForEvent('download');
  await page.getByRole('button', { name: 'Export evidence pack' }).click();
  const download = await downloadPromise;
  expect(download.suggestedFilename()).toBe('evidence-pack-2026-27-Q1.zip');
  const path = await download.path();
  expect(path).toBeTruthy();
  const bytes = readFileSync(path!);
  expect(bytes.subarray(0, 2).toString()).toBe('PK');
  expect(bytes.includes(Buffer.from('transactions.csv'))).toBeTruthy();
  expect(bytes.includes(Buffer.from('evidence/'))).toBeTruthy();
});

test('@claim:free-limit server stops a 26th free transaction', async ({ page }) => {
  await page.goto('/demo');
  const key = await page.evaluate(() => sessionStorage.getItem('demo:mtd-evidence-rail:workspace'));
  const records = Array.from({ length: 19 }, (_, i) => ({
    kind: 'expense', record_date: `2026-06-${String(i + 1).padStart(2, '0')}`,
    description: `Imported item ${i + 1}`, amount_pence: 100 + i, category: 'Office', source: 'bank',
  }));
  const imported = await page.request.post('/api/records/import', { headers: { 'X-Workspace-Key': key! }, data: { records } });
  expect(imported.status()).toBe(201);
  const bypass = await page.request.post('/api/records', {
    headers: { 'X-Workspace-Key': key! },
    data: { kind: 'expense', record_date: '2026-06-29', description: 'Direct API attempt', amount_pence: 300, category: 'Office', source: 'manual' },
  });
  expect(bypass.status()).toBe(402);
  expect((await bypass.json()).error).toContain('25 transactions');
  await page.reload();
  await expect(page.getByText('The free quarter is full.')).toBeVisible();
});

test('@claim:paid-limit server verifies a licence before allowing more than 25', async ({ page }) => {
  await page.goto('/demo');
  const key = await page.evaluate(() => sessionStorage.getItem('demo:mtd-evidence-rail:workspace'));
  const records = Array.from({ length: 20 }, (_, i) => ({
    kind: 'expense', record_date: `2026-06-${String(i + 1).padStart(2, '0')}`,
    description: `Paid item ${i + 1}`, amount_pence: 200 + i, category: 'Office', source: 'bank',
  }));
  const response = await page.request.post('/api/records/import', {
    headers: { 'X-Workspace-Key': key!, 'X-License-Key': 'fixture-valid-license' }, data: { records },
  });
  expect(response.status()).toBe(201);
  const workspace = await page.request.get('/api/workspace?from=2026-04-06&to=2026-07-05', { headers: { 'X-Workspace-Key': key! } });
  expect((await workspace.json()).summary.total).toBe(26);
});

test('@claim:atomic-import rejects the whole file when one row is invalid', async ({ page }) => {
  await page.goto('/demo');
  const key = await page.evaluate(() => sessionStorage.getItem('demo:mtd-evidence-rail:workspace'));
  const response = await page.request.post('/api/records/import', {
    headers: { 'X-Workspace-Key': key! },
    data: { records: [
      { kind: 'expense', record_date: '2026-06-20', description: 'Valid first row', amount_pence: 100, category: 'Office', source: 'bank' },
      { kind: 'expense', record_date: '2026-99-99', description: 'Invalid second row', amount_pence: 200, category: 'Office', source: 'bank' },
    ] },
  });
  expect(response.status()).toBe(400);
  const after = await page.request.get('/api/workspace?from=2026-04-06&to=2026-07-05', { headers: { 'X-Workspace-Key': key! } });
  expect((await after.json()).summary.total).toBe(6);
});

test('@claim:calendar-dates rejects impossible dates at the API edge', async ({ page }) => {
  await page.goto('/app');
  const key = await page.evaluate(() => localStorage.getItem('mtd-evidence-rail:workspace'));
  const response = await page.request.post('/api/records', {
    headers: { 'X-Workspace-Key': key! },
    data: { kind: 'expense', record_date: '2026-99-99', description: 'Impossible date', amount_pence: 100, category: 'Office', source: 'manual' },
  });
  expect(response.status()).toBe(400);
  expect((await response.json()).error).toBe('Enter a real calendar date.');
});

test('@claim:evidence-types accepts PDF, JPG, PNG, WebP, and text evidence', async ({ page }) => {
  await page.goto('/demo');
  const key = await page.evaluate(() => sessionStorage.getItem('demo:mtd-evidence-rail:workspace'));
  const workspace = await page.request.get('/api/workspace?from=2026-04-06&to=2026-07-05', { headers: { 'X-Workspace-Key': key! } });
  const recordId = (await workspace.json()).records[0].id as string;
  for (const [name, mime] of [['receipt.pdf','application/pdf'],['receipt.jpg','image/jpeg'],['receipt.png','image/png'],['receipt.webp','image/webp'],['note.txt','text/plain']]) {
    const response = await page.request.post(`/api/records/${recordId}/evidence`, {
      headers: { 'X-Workspace-Key': key! }, data: { name, mime, data_base64: 'dGVzdA==' },
    });
    expect(response.status(), mime).toBe(200);
  }
  const atLimit = Buffer.alloc(5 * 1024 * 1024, 1).toString('base64');
  const accepted = await page.request.post(`/api/records/${recordId}/evidence`, {
    headers: { 'X-Workspace-Key': key! }, data: { name: 'five-megabytes.pdf', mime: 'application/pdf', data_base64: atLimit },
  });
  expect(accepted.status()).toBe(200);
  const rejected = await page.request.post(`/api/records/${recordId}/evidence`, {
    headers: { 'X-Workspace-Key': key! }, data: { name: 'too-large.pdf', mime: 'application/pdf', data_base64: Buffer.alloc(5 * 1024 * 1024 + 1, 1).toString('base64') },
  });
  expect(rejected.status()).toBe(413);
});

test('@claim:workspace-delete removes the workspace and its evidence', async ({ page }) => {
  await page.goto('/app');
  const key = await page.evaluate(() => localStorage.getItem('mtd-evidence-rail:workspace'));
  const created = await page.request.post('/api/records', {
    headers: { 'X-Workspace-Key': key! },
    data: { kind: 'expense', record_date: '2026-05-10', description: 'Receipt to delete', amount_pence: 100, category: 'Office', source: 'manual' },
  });
  const recordId = (await created.json()).id as string;
  await page.request.post(`/api/records/${recordId}/evidence`, {
    headers: { 'X-Workspace-Key': key! }, data: { name: 'delete-me.txt', mime: 'text/plain', data_base64: 'dGVzdA==' },
  });
  const removed = await page.request.delete('/api/workspace', { headers: { 'X-Workspace-Key': key!, 'X-Confirm-Delete': 'delete' } });
  expect(removed.status()).toBe(204);
  expect((await page.request.get('/api/workspace', { headers: { 'X-Workspace-Key': key! } })).status()).toBe(404);
});

test('@claim:missing-review shows only transactions without evidence', async ({ page }) => {
  await page.goto('/demo');
  await page.getByRole('button', { name: 'Show missing evidence' }).click();
  await expect(page.getByText('2 shown')).toBeVisible();
  await expect(page.getByText('Community hall hire')).toBeVisible();
  await expect(page.getByText('Stationery from Paper Mill')).toHaveCount(0);
});

test('@claim:no-trackers demo core flow sends only same-origin requests', async ({ page }) => {
  const outgoing:string[] = [];
  page.on('request', request => outgoing.push(request.url()));
  await page.goto('/demo');
  await page.getByRole('button', { name: 'Show missing evidence' }).click();
  await expect(page.getByText('2 shown')).toBeVisible();
  expect(outgoing.length).toBeGreaterThan(2);
  for (const url of outgoing) expect(new URL(url).origin).toBe('http://127.0.0.1:8080');
});

test('@claim:license-return stores and verifies a returned licence', async ({ page }) => {
  await page.route('https://api.sociobot.in/**', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ valid: true, reason: 'ok', expires_at: null }) }));
  await page.goto('/?license=test-token-123');
  await expect(page).toHaveURL('/');
  expect(await page.evaluate(() => localStorage.getItem('sb_license:mtd-evidence-rail'))).toBe('test-token-123');
  await expect.poll(() => page.evaluate(() => JSON.parse(localStorage.getItem('sb_license_cache:mtd-evidence-rail') || '{}').valid)).toBe(true);
});

test('all routes have one h1 and no serious accessibility violations', async ({ page }) => {
  for (const path of ['/', '/demo', '/app', '/privacy', '/terms', '/not-a-page']) {
    const response = await page.goto(path);
    expect(response?.status()).toBe(path === '/not-a-page' ? 404 : 200);
    expect(await page.locator('h1').count()).toBe(1);
    if (path === '/demo') await expect(page.getByText('Community hall hire')).toBeVisible();
    const results = await new AxeBuilder({ page }).analyze();
    expect(results.violations.filter(v => ['serious', 'critical'].includes(v.impact || '')), path).toEqual([]);
  }
});

test('390px mobile and keyboard paths meet interaction requirements', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/');
  await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
  await page.keyboard.press('Tab');
  await expect(page.getByRole('link', { name: 'Skip to main content' })).toBeFocused();
  await page.getByRole('link', { name: 'Try it with sample data' }).focus();
  await page.keyboard.press('Enter');
  await expect(page).toHaveURL(/\/demo$/);
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth)).toBe(true);
  for (const link of await page.locator('header a, footer a').all()) {
    if (!(await link.isVisible())) continue;
    const box = await link.boundingBox();
    expect(box?.width).toBeGreaterThanOrEqual(44);
    expect(box?.height).toBeGreaterThanOrEqual(44);
  }
  const add = page.getByRole('button', { name: 'Add a transaction' });
  await add.click();
  await expect(page.locator('#kind')).toBeFocused();
  await page.keyboard.press('Escape');
  await expect(add).toBeFocused();
});

test('unversioned assets revalidate instead of caching forever', async ({ request }) => {
  const hero = await request.get('/assets/evidence-rail-hero.webp');
  expect(hero.headers()['cache-control']).toBe('public, max-age=3600, must-revalidate');
});
