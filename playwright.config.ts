import { defineConfig, devices } from '@playwright/test';

const liveBaseUrl = process.env.BASE_URL;

export default defineConfig({
  testDir: './tests',
  timeout: 30_000,
  expect: { timeout: 8_000 },
  fullyParallel: false,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL: liveBaseUrl || 'http://127.0.0.1:8080',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  ],
  webServer: liveBaseUrl ? undefined : [
    {
      command: 'node scripts/license-fixture.mjs',
      url: 'http://127.0.0.1:8198/health',
      timeout: 10_000,
      reuseExistingServer: !process.env.CI,
    },
    {
      command: 'STATIC_DIR=dist DATA_DIR=test-data PORT=8080 SOCIOBOT_API_BASE=http://127.0.0.1:8198/api/v1 cargo run',
      url: 'http://127.0.0.1:8080/health',
      timeout: 120_000,
      reuseExistingServer: !process.env.CI,
    },
  ],
});
