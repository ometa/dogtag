import { defineConfig, devices } from '@playwright/test';

// Use a fixed test port (different from dev port 3000) to avoid conflicts
// Can be overridden with TEST_PORT env var
const TEST_PORT = process.env.TEST_PORT || '3099';

/**
 * Playwright configuration for Dogtag integration tests
 *
 * Key behaviors:
 * - WebServer boots ONCE before all tests and stays running
 * - Tests run SEQUENTIALLY (one at a time, no parallelism)
 * - Each test file seeds its own data in beforeAll
 * - Global setup cleans stale test data before suite starts
 *
 * @see https://playwright.dev/docs/test-configuration
 */
export default defineConfig({
  testDir: './tests',

  /* Global setup runs once before all tests - cleans database */
  globalSetup: './tests/global-setup.ts',

  /* No parallel execution - tests run one at a time */
  fullyParallel: false,

  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,

  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0,

  /* Single worker - ensures sequential execution */
  workers: 1,

  /* Longer timeout for tests that seed data (default 30s is too short) */
  timeout: 120 * 1000, // 2 minutes per test

  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: 'html',

  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('/')`. */
    baseURL: process.env.BASE_URL || `http://localhost:${TEST_PORT}`,

    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: 'on-first-retry',

    /* Screenshot on failure */
    screenshot: 'only-on-failure',

    /* Longer navigation timeout */
    navigationTimeout: 30 * 1000,
  },

  /* Configure projects for major browsers */
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },

    /* Uncomment to test on more browsers
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },

    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    */
  ],

  /* Run your local dev server ONCE before all tests */
  webServer: {
    command: `bundle exec rails server -u webrick -p ${TEST_PORT}`,
    url: `http://localhost:${TEST_PORT}`,
    reuseExistingServer: true, // Always reuse if server already running
    timeout: 120 * 1000, // 2 minutes for server startup
    stdout: 'pipe',
    stderr: 'pipe',
  },
});
