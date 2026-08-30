import { chromium } from '@playwright/test';

const baseUrl = process.argv[2] || 'https://mtd-evidence-rail.sociobot.in';
const browser = await chromium.launch();

try {
  const runs = Array.from({ length: 12 }, async (_, index) => {
    const context = await browser.newContext();
    const page = await context.newPage();
    const failures = [];
    page.on('response', response => {
      if (response.url().includes('/api/') && response.status() >= 400) {
        failures.push(`${response.request().method()} ${response.url()} ${response.status()}`);
      }
    });
    await page.goto(`${baseUrl}/?demo=1`, { waitUntil: 'domcontentloaded' });
    await page.getByText('Community hall hire').waitFor({ state: 'visible', timeout: 15_000 });
    await page.getByText('Demo — sample data. Nothing is saved to your private workspace.').waitFor({ state: 'visible' });
    if (failures.length) throw new Error(`context ${index + 1}: ${failures.join(', ')}`);
    await context.close();
  });
  await Promise.all(runs);
  console.log('Live browser topology smoke passed: 12/12 fresh demo contexts loaded sample data.');
} finally {
  await browser.close();
}
