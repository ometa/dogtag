import { test, expect } from '@playwright/test';
import { execSync } from 'child_process';
import { readFileSync, unlinkSync, existsSync } from 'fs';
import { randomUUID } from 'crypto';
import { join } from 'path';

/**
 * Integration Test: User Registration Flow
 *
 * This test verifies the Authlogic user registration flow:
 * 1. Navigate to registration page
 * 2. Fill in registration form (first name, last name, email, phone, password)
 * 3. Submit the form
 * 4. Verify successful registration and automatic login
 *
 * This test is critical for catching Authlogic-related regressions after Rails upgrades.
 */

interface TestCredentials {
  first_name: string;
  last_name: string;
  email: string;
  phone: string;
  password: string;
}

// Generate unique ID for this test run (supports high concurrency)
const testUniqueId = randomUUID();
const credentialsFile = join(process.cwd(), 'tmp', `test_credentials_${testUniqueId}.json`);

let credentials: TestCredentials;

test.describe('User Registration Flow', () => {
  test.beforeAll(async () => {
    // Generate unique credentials for this test run
    execSync(`TEST_UNIQUE_ID=${testUniqueId} bundle exec rails test_seeds:user_registration`, { stdio: 'inherit' });

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

  test('registers a new user and logs them in automatically', async ({ page }) => {
    // Step 1: Navigate to registration page
    await test.step('Navigate to registration page', async () => {
      await page.goto('/');

      // Click the Login dropdown in top navigation
      await page.getByText('Login').first().click();
      await page.waitForTimeout(300);

      // Click the "Sign up" link in the dropdown menu
      const signupLink = page.getByRole('link', { name: /sign ?up|register|create account/i });
      await signupLink.click();

      // Verify we're on the registration page
      await expect(page).toHaveURL(/users\/new|account\/new|sign.?up|register/i);
    });

    // Step 2: Fill in registration form
    await test.step('Fill in registration form', async () => {
      // Wait for the form to load
      await page.waitForLoadState('networkidle');

      // Fill in first name
      const firstNameInput = page.locator('input#user_first_name');
      await firstNameInput.fill(credentials.first_name);

      // Fill in last name
      const lastNameInput = page.locator('input#user_last_name');
      await lastNameInput.fill(credentials.last_name);

      // Fill in email
      const emailInput = page.locator('input#user_email');
      await emailInput.fill(credentials.email);

      // Fill in phone
      const phoneInput = page.locator('input#user_phone');
      await phoneInput.fill(credentials.phone);

      // Fill in password
      const passwordInput = page.locator('input#user_password');
      await passwordInput.fill(credentials.password);

      // Fill in password confirmation
      const passwordConfirmInput = page.locator('input#user_password_confirmation');
      await passwordConfirmInput.fill(credentials.password);
    });

    // Step 3: Submit the form
    await test.step('Submit registration form', async () => {
      // Click the Save/Submit button
      const submitButton = page.getByRole('button', { name: /save|submit|register|sign ?up|create/i });
      await submitButton.click();

      // Wait for navigation to complete
      await page.waitForLoadState('networkidle');
    });

    // Step 4: Verify successful registration
    await test.step('Verify successful registration and automatic login', async () => {
      // Should see success message
      await expect(page.getByText(/account.*created|registration.*success|welcome/i)).toBeVisible({ timeout: 10000 });

      // Should be logged in - verify by clicking user dropdown and seeing logout option
      // The user icon dropdown is visible when logged in (fa-user icon)
      const userDropdown = page.locator('.navbar-nav .dropdown .fa-user').first();
      await userDropdown.click();
      await page.waitForTimeout(300);

      // Now the logout option should be visible in the dropdown
      await expect(page.getByText(/logout/i)).toBeVisible({ timeout: 5000 });
    });

    // Step 5: Verify can access user profile
    await test.step('Verify user profile accessible', async () => {
      // Navigate to account page
      await page.goto('/account');

      // Should see the user's full name on the profile page
      const fullName = `${credentials.first_name} ${credentials.last_name}`;
      await expect(page.getByRole('heading', { name: new RegExp(fullName, 'i') })).toBeVisible();
    });
  });
});
