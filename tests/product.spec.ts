import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import { readFileSync } from 'node:fs';

test('@claim:demo-isolation demo uses a separate 24-hour workspace', async ({ page }) => {
  let expiry:number|undefined;
  page.on('response', async response => {
    if (response.url().endsWith('/api/demo') && response.request().method() === 'POST') {
      expiry = (await response.json()).expires_in_hours;
    }
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

test('@claim:no-account starts a private workspace without sign-in', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('link', { name: 'Start a private workspace' }).click();
  await expect(page).toHaveURL(/\/app$/);
  await expect(page.getByRole('heading', { level: 1, name: 'Prepare your quarter record' })).toBeVisible();
  expect(await page.evaluate(() => localStorage.getItem('mtd-evidence-rail:workspace'))).toMatch(/^[a-f0-9]{64}$/);
  await expect(page.getByText('No transactions in this quarter')).toBeVisible();
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
  await expect(page.getByText('Evidence pack downloaded. Review missing rows before sharing.')).toBeVisible();
});

test('@claim:free-limit free quarters stop at 25 transactions', async ({ page }) => {
  await page.goto('/demo');
  const key = await page.evaluate(() => sessionStorage.getItem('demo:mtd-evidence-rail:workspace'));
  const records = Array.from({ length: 19 }, (_, i) => ({
    kind: 'expense', record_date: `2026-06-${String(i + 1).padStart(2, '0')}`,
    description: `Imported item ${i + 1}`, amount_pence: 100 + i, category: 'Office', source: 'bank',
  }));
  const result = await page.evaluate(async ({ key, records }) => {
    const response = await fetch('/api/records/import', { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-Workspace-Key': key! }, body: JSON.stringify({ records }) });
    return response.status;
  }, { key, records });
  expect(result).toBe(201);
  await page.reload();
  await expect(page.getByText('The free quarter is full.')).toBeVisible();
  await page.getByRole('button', { name: 'Add a transaction' }).click();
  await page.locator('#record-date').fill('2026-06-29');
  await page.locator('#description').fill('One too many');
  await page.locator('#amount').fill('3.00');
  await page.locator('#category').fill('Office');
  await page.getByRole('button', { name: 'Save transaction' }).click();
  await expect(page.getByText('The free quarter has 25 transactions.')).toBeVisible();
});

test('@claim:no-trackers demo core flow sends only same-origin requests', async ({ page }) => {
  const outgoing:string[] = [];
  page.on('request', request => outgoing.push(request.url()));
  await page.goto('/demo');
  await expect(page.getByText('Community hall hire')).toBeVisible();
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

test('landing and demo have no serious accessibility violations', async ({ page }) => {
  await page.goto('/');
  expect(await page.locator('h1').count()).toBe(1);
  let results = await new AxeBuilder({ page }).analyze();
  expect(results.violations.filter(v => ['serious', 'critical'].includes(v.impact || ''))).toEqual([]);
  await page.goto('/demo');
  await expect(page.getByText('Community hall hire')).toBeVisible();
  results = await new AxeBuilder({ page }).analyze();
  expect(results.violations.filter(v => ['serious', 'critical'].includes(v.impact || ''))).toEqual([]);
});

test('mobile and keyboard paths reach the main action', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/');
  await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
  await page.keyboard.press('Tab');
  await expect(page.getByRole('link', { name: 'Skip to main content' })).toBeFocused();
  await page.getByRole('link', { name: 'Try it with sample data' }).focus();
  await page.keyboard.press('Enter');
  await expect(page).toHaveURL(/\/demo$/);
  await expect(page.getByRole('button', { name: 'Add a transaction' })).toBeVisible();
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth)).toBe(true);
});
