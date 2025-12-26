import { test, expect } from '@playwright/test';
import { execSync } from 'child_process';
import { readFileSync, unlinkSync, existsSync } from 'fs';
import { randomUUID } from 'crypto';
import { join } from 'path';

interface TestCredentials {
  captain_email: string;
  captain_password: string;
  race_id: number;
  race_name: string;
  team_id: number;
  team_name: string;
}

// Generate unique ID for this test run (supports high concurrency)
const testUniqueId = randomUUID();
const credentialsFile = join(process.cwd(), 'tmp', `test_credentials_${testUniqueId}.json`);

let credentials: TestCredentials;

test.describe('Payment Requirements and Tiers', () => {
  test.beforeAll(async () => {
    // Seed test data with unique ID
    execSync(`TEST_UNIQUE_ID=${testUniqueId} bundle exec rails test_seeds:payment_tiers`, { stdio: 'inherit' });

    // Read credentials from file
    credentials = JSON.parse(readFileSync(credentialsFile, 'utf-8'));
  });

  test.afterAll(async () => {
    // Clean up credentials file
    if (existsSync(credentialsFile)) {
      unlinkSync(credentialsFile);
    }
  });

  test('displays both payment requirements with correct active tier', async ({ page }) => {
    // Login
    await page.goto('/');
    await page.getByText('Login').first().click();
    await page.waitForTimeout(300);
    const dropdownLinks = page.getByRole('link', { name: 'Login' });
    await dropdownLinks.last().click();

    const emailInput = page.locator('input[type="text"]').first();
    await emailInput.fill(credentials.captain_email);
    const passwordInput = page.locator('input[type="password"]');
    await passwordInput.fill(credentials.captain_password);
    await page.getByRole('button', { name: /log ?in/i }).click();

    await expect(page.getByText(/login successful/i)).toBeVisible();

    // Navigate to team page using credentials
    await page.getByRole('link', { name: /races/i }).click();
    await page.getByText(credentials.race_name).first().click();
    await page.getByText(credentials.team_name).click();

    // Click Payments tab
    await page.getByRole('link', { name: /payments/i }).first().click();
    await page.waitForTimeout(500);

    // Verify both payment requirements are visible
    await expect(page.getByText('Registration Fee')).toBeVisible();
    await expect(page.getByText('Team Fee')).toBeVisible();

    // Verify both show $50 price and Team Fee shows upcoming $60 tier
    await expect(page.locator('text=50.00').first()).toBeVisible();
    await expect(page.locator('text=60.00')).toBeVisible();

    // Verify mock payment buttons are visible
    const payButtons = await page.getByText('Pay (Mock Success)').all();
    expect(payButtons.length).toBe(2);

    // Complete first payment (Registration Fee)
    await payButtons[0].click();
    await page.waitForLoadState('networkidle');
    await expect(page.getByText(/mock payment successful/i)).toBeVisible();

    // Return to payments tab
    await page.getByRole('link', { name: /payments/i }).first().click();
    await page.waitForTimeout(500);

    // Complete second payment (Team Fee)
    await page.getByText('Pay (Mock Success)').click();

    // Verify team finalized (same success flow as test #1)
    await expect(page.locator('#congratulations-user-success')).toBeVisible();
  });
});
