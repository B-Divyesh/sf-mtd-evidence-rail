import { test, expect, type Page } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';
import { readFileSync } from 'node:fs';

async function openReady(page:Page,path:'/app'|'/demo'|'/?demo=1'){
  await page.goto(path);
  await expect(page.locator('#records-view .summary-line')).toBeVisible();
  await expect(page.getByRole('button',{name:'Add a transaction'})).toBeEnabled();
}

test('@claim:demo-isolation demo isolates private workspace and subscription state for 24 hours', async ({ page }) => {
  let expiry:number|undefined;
  const outgoing:{url:string; license:string|undefined}[]=[];
  const realWorkspace='a'.repeat(64);
  const realLicense='real-subscription-token';
  const realCache=JSON.stringify({valid:true,checked_at:1});
  await page.addInitScript(([workspace, license, cache]) => {
    localStorage.setItem('mtd-evidence-rail:workspace', workspace);
    localStorage.setItem('sb_license:mtd-evidence-rail', license);
    localStorage.setItem('sb_license_cache:mtd-evidence-rail', cache);
  }, [realWorkspace, realLicense, realCache]);
  page.on('response', async response => {
    if (response.url().endsWith('/api/demo') && response.request().method() === 'POST') expiry = (await response.json()).expires_in_hours;
  });
  page.on('request', request => outgoing.push({url:request.url(),license:request.headers()['x-license-key']}));
  await openReady(page,'/?demo=1');
  await expect(page).toHaveURL(/\?demo=1$/);
  await expect(page.getByText('Demo — sample data. Nothing is saved to your private workspace.')).toBeVisible();
  await expect(page.getByText('Changes stay in this 24-hour demo.')).toHaveCount(0);
  await expect(page.getByRole('link', { name: 'Start a private workspace' })).toHaveAttribute('href', '/app');
  await expect(page.getByText('6', { exact: true }).first()).toBeVisible();
  const firstKey = await page.evaluate(() => sessionStorage.getItem('demo:mtd-evidence-rail:workspace'));
  expect(firstKey).toMatch(/^demo:[a-f0-9]{64}$/);
  expect(await page.evaluate(() => localStorage.getItem('mtd-evidence-rail:workspace'))).toBe(realWorkspace);
  expect(await page.evaluate(() => localStorage.getItem('sb_license:mtd-evidence-rail'))).toBe(realLicense);
  expect(await page.evaluate(() => localStorage.getItem('sb_license_cache:mtd-evidence-rail'))).toBe(realCache);
  expect(expiry).toBe(24);
  const productOrigin = new URL(page.url()).origin;
  for (const request of outgoing) {
    expect(new URL(request.url).origin).toBe(productOrigin);
    expect(request.license).toBeUndefined();
  }
  await page.getByRole('button', { name: 'Reset demo' }).click();
  await expect.poll(() => page.evaluate(() => sessionStorage.getItem('demo:mtd-evidence-rail:workspace'))).not.toBe(firstKey);
  expect(await page.evaluate(() => localStorage.getItem('mtd-evidence-rail:workspace'))).toBe(realWorkspace);
  expect(await page.evaluate(() => localStorage.getItem('sb_license:mtd-evidence-rail'))).toBe(realLicense);
  expect(await page.evaluate(() => localStorage.getItem('sb_license_cache:mtd-evidence-rail'))).toBe(realCache);
});

test('@claim:no-account starts without sign-in and keeps the key on this device', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('navigation').getByRole('link', { name: 'Privacy' }).click();
  await expect(page.getByText('Your browser stores a 64-character workspace key.')).toBeVisible();
  await page.goto('/');
  await page.getByRole('link', { name: 'Start a private workspace' }).click();
  await expect(page).toHaveURL(/\/app$/);
  await expect(page.getByRole('heading', { level: 1, name: 'Prepare your quarter record' })).toBeVisible();
  await expect(page.getByText('No transactions in this quarter')).toBeVisible();
  await expect.poll(() => page.evaluate(() => localStorage.getItem('mtd-evidence-rail:workspace'))).toMatch(/^[a-f0-9]{64}$/);
  expect(await page.evaluate(() => sessionStorage.getItem('demo:mtd-evidence-rail:workspace'))).toBeNull();
});

test('@claim:workspace-key-recovery copies a key and opens the same records on another device', async ({ page }) => {
  await page.addInitScript(() => {
    Object.defineProperty(navigator, 'clipboard', {
      configurable: true,
      value: { writeText: async (value:string) => { (window as typeof window & { __copiedKey?:string }).__copiedKey = value; } },
    });
  });
  await openReady(page, '/app');
  const key = await page.evaluate(() => localStorage.getItem('mtd-evidence-rail:workspace'));
  const created = await page.request.post('/api/records', {
    headers: { 'X-Workspace-Key': key! },
    data: { kind: 'expense', record_date: '2026-08-20', description: 'Shared printer ink', amount_pence: 2499, category: 'Office', source: 'manual' },
  });
  expect(created.status()).toBe(201);
  await page.reload();
  await expect(page.getByText('Shared printer ink')).toBeVisible();
  await page.getByRole('button', { name: 'Workspace settings' }).click();
  await page.getByRole('button', { name: 'Copy workspace access key' }).click();
  await expect(page.getByText('Workspace access key copied. Keep it private.')).toBeVisible();
  expect(await page.evaluate(() => (window as typeof window & { __copiedKey?:string }).__copiedKey)).toBe(key);

  await page.evaluate(() => localStorage.removeItem('mtd-evidence-rail:workspace'));
  await page.goto('/');
  await page.getByRole('button', { name: 'Open an existing workspace' }).click();
  await expect(page.locator('#workspace-access-key')).toBeFocused();
  await page.locator('#workspace-access-key').fill('0'.repeat(64));
  await page.getByRole('button', { name: 'Open workspace' }).click();
  await expect(page.locator('#access-error')).toHaveText('That workspace key was not found. Check it and try again.');
  await page.locator('#workspace-access-key').fill(key!);
  await page.getByRole('button', { name: 'Open workspace' }).click();
  await expect(page).toHaveURL(/\/app$/);
  await expect(page.getByText('Shared printer ink')).toBeVisible();
  expect(await page.evaluate(() => localStorage.getItem('mtd-evidence-rail:workspace'))).toBe(key);
});

test('@claim:workspace-key-auth every private API route rejects missing and wrong keys', async ({ page }) => {
  await openReady(page, '/app');
  const key = await page.evaluate(() => localStorage.getItem('mtd-evidence-rail:workspace'));
  const recordInput = { kind: 'expense', record_date: '2026-08-20', description: 'Access boundary check', amount_pence: 1250, category: 'Office', source: 'manual' };
  const created = await page.request.post('/api/records', { headers: { 'X-Workspace-Key': key! }, data: recordInput });
  expect(created.status()).toBe(201);
  const recordId = (await created.json()).id as string;
  const wrong = 'f'.repeat(64) === key ? 'e'.repeat(64) : 'f'.repeat(64);
  const routes = [
    { method: 'get', url: '/api/workspace?from=2026-07-06&to=2026-10-05' },
    { method: 'post', url: '/api/records', data: recordInput },
    { method: 'post', url: '/api/records/import', data: { records: [recordInput] } },
    { method: 'post', url: `/api/records/${recordId}/evidence`, data: { name: 'proof.txt', mime: 'text/plain', data_base64: 'dGVzdA==' } },
    { method: 'delete', url: `/api/records/${recordId}/evidence` },
    { method: 'delete', url: `/api/records/${recordId}` },
    { method: 'get', url: '/api/export?from=2026-07-06&to=2026-10-05' },
    { method: 'delete', url: '/api/workspace', headers: { 'X-Confirm-Delete': 'delete' } },
  ] as const;
  for (const route of routes) {
    for (const invalid of [undefined, wrong]) {
      const headers:Record<string,string> = { ...('headers' in route ? route.headers : {}) };
      if (invalid) headers['X-Workspace-Key'] = invalid;
      const response = await page.request.fetch(route.url, { method: route.method, headers, data: 'data' in route ? route.data : undefined });
      expect([401, 404], `${route.method.toUpperCase()} ${route.url} with ${invalid ? 'wrong' : 'missing'} key`).toContain(response.status());
    }
  }

  expect((await page.request.get('/api/workspace?from=2026-07-06&to=2026-10-05', { headers: { 'X-Workspace-Key': key! } })).status()).toBe(200);
  expect((await page.request.post('/api/records/import', { headers: { 'X-Workspace-Key': key! }, data: { records: [{ ...recordInput, description: 'Valid import' }] } })).status()).toBe(201);
  expect((await page.request.post(`/api/records/${recordId}/evidence`, { headers: { 'X-Workspace-Key': key! }, data: { name: 'proof.txt', mime: 'text/plain', data_base64: 'dGVzdA==' } })).status()).toBe(200);
  expect((await page.request.delete(`/api/records/${recordId}/evidence`, { headers: { 'X-Workspace-Key': key! } })).status()).toBe(200);
  expect((await page.request.get('/api/export?from=2026-07-06&to=2026-10-05', { headers: { 'X-Workspace-Key': key! } })).status()).toBe(200);
  expect((await page.request.delete(`/api/records/${recordId}`, { headers: { 'X-Workspace-Key': key! } })).status()).toBe(204);
  expect((await page.request.delete('/api/workspace', { headers: { 'X-Workspace-Key': key!, 'X-Confirm-Delete': 'delete' } })).status()).toBe(204);
});

test('@claim:quarter-capture saves income and expenses in the dated quarter', async ({ page }) => {
  await openReady(page,'/app');
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
  await openReady(page,'/demo');
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
  await openReady(page,'/demo');
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
  await openReady(page,'/demo');
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
  await page.goto('/');
  await expect(page.getByText('The server verifies an active subscription before accepting more than 25 transactions.')).toBeVisible();
  await openReady(page,'/demo');
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
  await openReady(page,'/demo');
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
  await openReady(page,'/app');
  const key = await page.evaluate(() => localStorage.getItem('mtd-evidence-rail:workspace'));
  const response = await page.request.post('/api/records', {
    headers: { 'X-Workspace-Key': key! },
    data: { kind: 'expense', record_date: '2026-99-99', description: 'Impossible date', amount_pence: 100, category: 'Office', source: 'manual' },
  });
  expect(response.status()).toBe(400);
  expect((await response.json()).error).toBe('Enter a real calendar date.');
});

test('@claim:evidence-types accepts PDF, JPG, PNG, WebP, and text evidence', async ({ page }) => {
  await openReady(page,'/demo');
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
  await openReady(page,'/app');
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
  await openReady(page,'/demo');
  await page.getByRole('button', { name: 'Show missing evidence' }).click();
  await expect(page.getByText('2 shown')).toBeVisible();
  await expect(page.getByText('Community hall hire')).toBeVisible();
  await expect(page.getByText('Stationery from Paper Mill')).toHaveCount(0);
});

test('@claim:demo-sample starts and resets with six transactions, four linked files, and two missing items', async ({ page }) => {
  await openReady(page, '/?demo=1');
  for (let pass = 0; pass < 2; pass++) {
    const key = await page.evaluate(() => sessionStorage.getItem('demo:mtd-evidence-rail:workspace'));
    const response = await page.request.get('/api/workspace?from=2026-04-06&to=2026-07-05', { headers: { 'X-Workspace-Key': key! } });
    const workspace = await response.json();
    expect(workspace.records).toHaveLength(6);
    expect(workspace.records.filter((record:{evidence_name:string|null}) => Boolean(record.evidence_name))).toHaveLength(4);
    expect(workspace.records.filter((record:{evidence_name:string|null}) => !record.evidence_name)).toHaveLength(2);
    if (pass === 0) {
      await page.getByRole('button', { name: 'Reset demo' }).click();
      await expect(page.locator('#records-view .summary-line')).toBeVisible();
    }
  }
});

test('@claim:no-trackers demo core flow sends only same-origin requests', async ({ page }) => {
  const outgoing:string[] = [];
  page.on('request', request => outgoing.push(request.url()));
  await openReady(page,'/demo');
  await page.getByRole('button', { name: 'Show missing evidence' }).click();
  await expect(page.getByText('2 shown')).toBeVisible();
  expect(outgoing.length).toBeGreaterThan(2);
  const productOrigin = new URL(page.url()).origin;
  for (const url of outgoing) expect(new URL(url).origin).toBe(productOrigin);
});

test('offline connection gives a clear recovery notice', async ({ page }) => {
  await openReady(page,'/demo');
  await page.evaluate(() => window.dispatchEvent(new Event('offline')));
  await expect(page.getByText('You are offline. Saved records will load again after you reconnect.')).toBeVisible();
});

test('@claim:license-return stores and verifies a returned licence', async ({ page }) => {
  await page.route('https://api.sociobot.in/**', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ valid: true, reason: 'ok', expires_at: null }) }));
  await page.goto('/?license=test-token-123');
  await expect(page).toHaveURL('/');
  expect(await page.evaluate(() => localStorage.getItem('sb_license:mtd-evidence-rail'))).toBe('test-token-123');
  await expect.poll(() => page.evaluate(() => JSON.parse(localStorage.getItem('sb_license_cache:mtd-evidence-rail') || '{}').valid)).toBe(true);
});

test('all routes have one h1 and no accessibility violations', async ({ page }) => {
  for (const path of ['/', '/demo', '/app', '/privacy', '/terms', '/not-a-page']) {
    const response = await page.goto(path);
    expect(response?.status()).toBe(path === '/not-a-page' ? 404 : 200);
    expect(await page.locator('h1').count()).toBe(1);
    if (path === '/demo') {
      await expect(page.getByText('Community hall hire')).toBeVisible();
      await expect(page.getByRole('complementary', { name: 'Demo controls' })).toBeVisible();
    }
    const results = await new AxeBuilder({ page }).analyze();
    expect(results.violations, path).toEqual([]);
  }
});

test('routes set titles, canonical URLs, focus, legal links, and a real 404', async ({ page }) => {
  const pages = [
    ['/', 'MTD Evidence Rail — link expenses to evidence', 'https://mtd-evidence-rail.sociobot.in/'],
    ['/demo', 'Demo — MTD Evidence Rail', 'https://mtd-evidence-rail.sociobot.in/demo'],
    ['/app', 'Quarter — MTD Evidence Rail', 'https://mtd-evidence-rail.sociobot.in/app'],
    ['/privacy', 'Privacy — MTD Evidence Rail', 'https://mtd-evidence-rail.sociobot.in/privacy'],
    ['/terms', 'Terms — MTD Evidence Rail', 'https://mtd-evidence-rail.sociobot.in/terms'],
  ] as const;
  for (const [path, title, canonical] of pages) {
    const response = await page.goto(path);
    expect(response?.status(), path).toBe(200);
    await expect(page).toHaveTitle(title);
    await expect(page.locator('link[rel="canonical"]')).toHaveAttribute('href', canonical);
    await expect(page.locator('meta[name="description"]')).toHaveAttribute('content', /.+/);
    await expect(page.locator('meta[property="og:image"]')).toHaveAttribute('content', /social-card\.webp$/);
    await expect(page.getByRole('link', { name: 'Privacy', exact: true }).last()).toHaveAttribute('href', '/privacy');
    await expect(page.getByRole('link', { name: 'Terms', exact: true }).last()).toHaveAttribute('href', '/terms');
  }
  await page.goto('/');
  await page.getByRole('navigation').getByRole('link', { name: 'Privacy' }).click();
  await expect(page.getByRole('heading', { level: 1 })).toBeFocused();
  await page.goBack();
  await expect(page.getByRole('heading', { level: 1 })).toBeFocused();
  const missing = await page.goto('/not-a-page');
  expect(missing?.status()).toBe(404);
  await expect(page).toHaveTitle('Page not found — MTD Evidence Rail');
  await expect(page.getByRole('link', { name: 'Return home' })).toHaveAttribute('href', '/');
});

test('390px mobile and keyboard paths meet interaction requirements', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/');
  await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
  await page.keyboard.press('Tab');
  await expect(page.getByRole('link', { name: 'Skip to main content' })).toBeFocused();
  await page.getByRole('link', { name: 'Try it with sample data' }).focus();
  await page.keyboard.press('Enter');
  await expect(page).toHaveURL(/\?demo=1$/);
  await expect(page.getByText('Teaching card supplies', { exact: true }).first()).toBeVisible();
  await expect(page.getByText('6 transactions', { exact: true }).first()).toBeVisible();
  const sampleBox = await page.getByText('Teaching card supplies', { exact: true }).first().boundingBox();
  expect((sampleBox?.y || 1000) + (sampleBox?.height || 0)).toBeLessThanOrEqual(844);
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

test('390px at 200% text size has no horizontal overflow', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.route('**/*.css', async route => {
    const stylesheet = await route.fetch();
    await route.fulfill({ response: stylesheet, body: `${await stylesheet.text()}\nhtml { font-size: 200%; }` });
  });
  await page.goto('/');
  await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
  const dimensions = await page.evaluate(() => ({
    clientWidth: document.documentElement.clientWidth,
    scrollWidth: document.documentElement.scrollWidth,
    overflowing: [...document.querySelectorAll<HTMLElement>('*')].map(element => {
      const rect = element.getBoundingClientRect();
      return { tag: element.tagName, className: element.className, right: rect.right, text: element.innerText?.slice(0, 48) };
    }).filter(element => element.right > document.documentElement.clientWidth + 1),
  }));
  expect(dimensions.scrollWidth <= dimensions.clientWidth).toBe(true);
  for (const selector of ['.site-header', '.hero-copy', '.price-ticket', '.site-footer']) {
    const box = await page.locator(selector).boundingBox();
    expect(box?.x, selector).toBeGreaterThanOrEqual(0);
    expect((box?.x || 0) + (box?.width || 0), selector).toBeLessThanOrEqual(390);
  }
});

test('desktop first screen shows the job, audience, action, and three facts', async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto('/');
  await expect(page.getByRole('heading', { level: 1, name: 'Link each expense to evidence' })).toBeVisible();
  await expect(page.getByText('For UK sole traders, tutors, and small club operators preparing an MTD quarterly update.')).toBeVisible();
  await expect(page.getByRole('link', { name: 'Try it with sample data' })).toBeVisible();
  const facts = await page.locator('.facts').boundingBox();
  expect(facts).not.toBeNull();
  expect(facts!.y + facts!.height).toBeLessThanOrEqual(900);
});

test('subscription copy is monthly across the product, terms, and README', async ({ page }) => {
  for (const [path, expected] of [
    ['/', '£15/month for more than 25 transactions.'],
    ['/terms', 'The current checkout offers a £15 monthly subscription.'],
  ] as const) {
    await page.goto(path);
    const copy = await page.locator('main').innerText();
    expect(copy).toContain(expected);
    expect(copy.toLowerCase()).not.toContain('£15 once');
    expect(copy.toLowerCase()).not.toContain('one-time');
  }
  const readme = readFileSync('README.md', 'utf8').toLowerCase();
  expect(readme).toContain('£15/month subscription');
  expect(readme).not.toContain('£15 once');
  expect(readme).not.toContain('one-time');
});

test('terms limit billing statements to checkout and active-access outcomes', async ({ page }) => {
  await page.goto('/terms');
  await expect(page.getByRole('heading', { level: 2, name: 'Monthly subscription' })).toBeVisible();
  await expect(page.getByText('The current checkout offers a £15 monthly subscription.')).toBeVisible();
  await expect(page.getByText('An active subscription allows more than 25 transactions in a quarter.')).toBeVisible();
  const terms = (await page.locator('main').innerText()).toLowerCase();
  expect(terms).not.toContain('renews monthly');
  expect(terms).not.toContain('until you cancel');
  expect(terms).not.toContain('billing terms appear before you pay');
});

test('release-blocking copy and 44px inline-link regressions stay fixed', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/');
  const landingText = await page.locator('main').innerText();
  for (const removed of ['Three stops', 'Keep every quarter on the rail', 'unlimited transactions', 'Quarterly evidence, in order', 'Bank lines, invoices, and receipts', 'Clear boundaries', 'Your records stay under your control']) {
    expect(landingText).not.toContain(removed);
  }
  await expect(page.getByText('Evidence for your MTD quarter', { exact: true })).toBeVisible();
  await expect(page.getByText('Transactions, invoices, and receipts appear in one dated view.')).toBeVisible();
  await expect(page.getByText('What this tool covers', { exact: true })).toBeVisible();
  await expect(page.getByRole('heading', { name: 'Workspace privacy, export, and deletion' })).toBeVisible();
  await expect(page.getByText('How it works', { exact: true })).toBeVisible();
  await expect(page.getByRole('heading', { name: 'Monthly subscription limits' })).toBeVisible();
  await expect(page.getByRole('link', { name: 'Open £15/month checkout' })).toBeVisible();

  const terms = page.locator('.price-ticket .help a', { hasText: 'terms' });
  const termsBox = await terms.boundingBox();
  expect(termsBox?.width).toBeGreaterThanOrEqual(44);
  expect(termsBox?.height).toBeGreaterThanOrEqual(44);

  for (const [path, name] of [['/privacy', 'privacy@sociobot.in'], ['/terms', 'support@sociobot.in']] as const) {
    await page.goto(path);
    const link = page.getByRole('link', { name });
    const box = await link.boundingBox();
    expect(box?.width).toBeGreaterThanOrEqual(44);
    expect(box?.height).toBeGreaterThanOrEqual(44);
  }

  await page.goto('/not-a-page');
  await expect(page.getByText('Page not found', { exact: true }).first()).toBeVisible();
  await expect(page.locator('main')).not.toContainText('The rail ends here');

  const readme = readFileSync('README.md', 'utf8');
  expect(readme).toContain('Demo keys and data are kept separate from\nprivate workspaces.');
  expect(readme).toContain('The deployment stops if shared storage is unavailable.');
  for (const removed of [
    'Demo creation has a stricter limit',
    'database namespace',
    'Azure revision',
    'container filesystem',
    'source-owned topology',
    'managed-identity',
    'management-API fixtures',
    'restrictive CSP',
    'Use one workspace for every quarter',
    'Start for real',
  ]) {
    expect(readme).not.toContain(removed);
  }
});

test('unversioned assets revalidate instead of caching forever', async ({ request }) => {
  const hero = await request.get('/assets/evidence-rail-hero.webp');
  expect(hero.headers()['cache-control']).toBe('public, max-age=3600, must-revalidate');
});
