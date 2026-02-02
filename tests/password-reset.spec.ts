import { test, expect } from '@playwright/test';
import { execSync } from 'child_process';
import { readFileSync, unlinkSync, existsSync } from 'fs';
import { randomUUID } from 'crypto';
import { join } from 'path';

/**
 * Integration Test: Password Reset Flow
 *
 * This test verifies the Authlogic password reset flow:
 * 1. Create a user with known password
 * 2. Request password reset via email form
 * 3. Verify reset email would be sent (flash message)
 * 4. Navigate to reset link using perishable token
 * 5. Set new password
 * 6. Verify can login with new password
 *
 * This test is critical for catching Authlogic perishable token regressions after Rails upgrades.
 */

interface TestCredentials {
  user_email: string;
  old_password: string;
  new_password: string;
  user_id: number;
  perishable_token?: string;
}

// Generate unique ID for this test run (supports high concurrency)
const testUniqueId = randomUUID();
const credentialsFile = join(process.cwd(), 'tmp', `test_credentials_${testUniqueId}.json`);

let credentials: TestCredentials;

test.describe('Password Reset Flow', () => {
  test.beforeAll(async () => {
    // Seed test user
    execSync(`TEST_UNIQUE_ID=${testUniqueId} bundle exec rails test_seeds:password_reset`, { stdio: 'inherit' });

    // Read credentials from file
    credentials = JSON.parse(readFileSync(credentialsFile, 'utf-8'));
  });

  test.afterAll(async () => {
    // Clean up credentials file
    if (existsSync(credentialsFile)) {
      unlinkSync(credentialsFile);
    }
    console.log('\n📝 Reminder: Run `rails test_seeds:cleanup` to remove test data');
  });

  test('resets password and allows login with new password', async ({ page }) => {
    // Step 1: Navigate to password reset page
    await test.step('Navigate to password reset page', async () => {
      await page.goto('/');

      // Click the Login dropdown in top navigation
      await page.getByText('Login').first().click();
      await page.waitForTimeout(300);

      // Click the Login link to get to login page
      const loginLinks = page.getByRole('link', { name: 'Login' });
      await loginLinks.last().click();

      // Wait for login page to load
      await page.waitForLoadState('networkidle');

      // Look for "Forgot your password?" link on login page
      const forgotPasswordLink = page.getByRole('link', { name: /forgot.*password/i });
      await forgotPasswordLink.click();

      // Verify we're on the password reset page
      await expect(page).toHaveURL(/password_resets\/new/i);
    });

    // Step 2: Request password reset
    await test.step('Request password reset', async () => {
      // Fill in email address
      const emailInput = page.locator('input#email, input[name="email"]');
      await emailInput.fill(credentials.user_email);

      // Submit the form
      const submitButton = page.getByRole('button', { name: /reset|submit|send/i });
      await submitButton.click();

      // Verify success message
      await expect(page.getByText(/instructions.*emailed|email.*sent|check.*email/i)).toBeVisible({ timeout: 10000 });
    });

    // Step 3: Generate perishable token (simulates clicking email link)
    await test.step('Generate perishable token', async () => {
      // In a real scenario, the user would click a link in their email.
      // For testing, we generate the token via rake task and navigate directly.
      execSync(`TEST_UNIQUE_ID=${testUniqueId} bundle exec rails test_seeds:password_reset_token`, { stdio: 'inherit' });

      // Re-read credentials to get the perishable token
      credentials = JSON.parse(readFileSync(credentialsFile, 'utf-8'));
      expect(credentials.perishable_token).toBeTruthy();
    });

    // Step 4: Navigate to password reset form using token
    await test.step('Navigate to password reset form', async () => {
      // Navigate to the password reset edit page with the perishable token
      await page.goto(`/password_resets/${credentials.perishable_token}/edit`);

      // Verify we're on the password update page by checking for the heading
      await expect(page.getByRole('heading', { name: /update.*password/i })).toBeVisible();
    });

    // Step 5: Set new password
    await test.step('Set new password', async () => {
      // Fill in new password
      const passwordInput = page.locator('input#password, input[name="password"]').first();
      await passwordInput.fill(credentials.new_password);

      // Fill in password confirmation
      const confirmInput = page.locator('input#password_confirmation, input[name="password_confirmation"]');
      await confirmInput.fill(credentials.new_password);

      // Submit the form
      const submitButton = page.getByRole('button', { name: /update|submit|save|change/i });
      await submitButton.click();

      // Verify success message
      await expect(page.getByText(/password.*updated|password.*changed|success/i)).toBeVisible({ timeout: 10000 });
    });

    // Step 6: Logout (user is auto-logged in after password reset)
    await test.step('Logout', async () => {
      // Click user dropdown first to reveal logout link
      const userDropdown = page.locator('.navbar-nav .dropdown .fa-user').first();
      await userDropdown.click();
      await page.waitForTimeout(300);

      // Click logout link (need to handle the confirmation dialog)
      page.on('dialog', dialog => dialog.accept());
      const logoutLink = page.getByRole('link', { name: /logout/i }).first();
      await logoutLink.click();

      // Verify logged out
      await expect(page.getByText(/logged ?out|signed ?out|logout successful/i)).toBeVisible({ timeout: 5000 });
    });

    // Step 7: Verify can login with new password
    await test.step('Login with new password', async () => {
      // Navigate to login page
      await page.getByText('Login').first().click();
      await page.waitForTimeout(300);
      const loginLinks = page.getByRole('link', { name: 'Login' });
      await loginLinks.last().click();

      // Fill in email
      const emailInput = page.locator('input[type="text"]').first();
      await emailInput.fill(credentials.user_email);

      // Fill in new password
      const passwordInput = page.locator('input[type="password"]');
      await passwordInput.fill(credentials.new_password);

      // Submit login form
      await page.getByRole('button', { name: /log ?in/i }).click();

      // Verify successful login
      await expect(page.getByText(/login successful/i)).toBeVisible({ timeout: 10000 });
    });

    // Step 8: Verify old password no longer works
    await test.step('Verify old password no longer works', async () => {
      // Logout first - click user dropdown then logout link
      const userDropdown = page.locator('.navbar-nav .dropdown .fa-user').first();
      await userDropdown.click();
      await page.waitForTimeout(300);
      const logoutLink = page.getByRole('link', { name: /logout/i }).first();
      await logoutLink.click();
      await page.waitForTimeout(500);

      // Try to login with old password
      await page.getByText('Login').first().click();
      await page.waitForTimeout(300);
      const loginLinks = page.getByRole('link', { name: 'Login' });
      await loginLinks.last().click();

      const emailInput = page.locator('input[type="text"]').first();
      await emailInput.fill(credentials.user_email);

      const passwordInput = page.locator('input[type="password"]');
      await passwordInput.fill(credentials.old_password);

      await page.getByRole('button', { name: /log ?in/i }).click();

      // Should see error message (login failed)
      await expect(page.getByText('Login failed.')).toBeVisible({ timeout: 10000 });
    });
  });
});
