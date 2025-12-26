import { test, expect } from '@playwright/test';
import { execSync } from 'child_process';

test.describe('Payment Requirements and Tiers', () => {
  test.beforeAll(async () => {
    execSync('bundle exec rails test_seeds:cleanup && bundle exec rails test_seeds:payment_tiers', { stdio: 'inherit' });
  });

  test('displays both payment requirements with correct active tier', async ({ page }) => {
    const captain = {
      email: 'test+captain@example.com',
      password: 'password123',
    };

    // Login
    await page.goto('/');
    await page.getByText('Login').first().click();
    await page.waitForTimeout(300);
    const dropdownLinks = page.getByRole('link', { name: 'Login' });
    await dropdownLinks.last().click();

    const emailInput = page.locator('input[type="text"]').first();
    await emailInput.fill(captain.email);
    const passwordInput = page.locator('input[type="password"]');
    await passwordInput.fill(captain.password);
    await page.getByRole('button', { name: /log ?in/i }).click();

    await expect(page.getByText(/login successful/i)).toBeVisible();

    // Navigate to team page
    await page.getByRole('link', { name: /races/i }).click();
    await page.getByText(/Test Race Payment/).first().click();
    await page.getByText(/Test Team Payment/i).click();

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
