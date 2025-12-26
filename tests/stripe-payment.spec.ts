import { test, expect } from '@playwright/test';
import { execSync } from 'child_process';
import { readFileSync, unlinkSync, existsSync } from 'fs';
import { randomUUID } from 'crypto';
import { join } from 'path';
import * as dotenv from 'dotenv';

/**
 * Integration Test: Stripe Payment Flow
 *
 * This test verifies the Stripe payment integration:
 * 1. Team has 5/5 members (full team)
 * 2. Team has 1 payment requirement (real Stripe, not mock)
 * 3. Captain logs in and navigates to payments
 * 4. Captain clicks Pay button to open Stripe Checkout
 * 5. Captain fills in test card details
 * 6. Payment completes successfully
 * 7. Team becomes finalized
 *
 * REQUIRES: .env file with STRIPE_PUBLISHABLE_KEY and STRIPE_SECRET_KEY
 */

interface TestCredentials {
  captain_email: string;
  captain_password: string;
  race_id: number;
  race_name: string;
  team_id: number;
  team_name: string;
  payment_amount: number;
}

// Load .env file and verify Stripe credentials exist
function verifyStripeCredentials(): void {
  const envPath = join(process.cwd(), '.env');

  if (!existsSync(envPath)) {
    throw new Error(
      'STRIPE TEST FAILED: .env file not found.\n' +
      'Please create a .env file with STRIPE_PUBLISHABLE_KEY and STRIPE_SECRET_KEY.\n' +
      'See .env.example for the required format.'
    );
  }

  dotenv.config({ path: envPath });

  if (!process.env.STRIPE_PUBLISHABLE_KEY || !process.env.STRIPE_SECRET_KEY) {
    throw new Error(
      'STRIPE TEST FAILED: Missing Stripe credentials in .env file.\n' +
      'Please ensure STRIPE_PUBLISHABLE_KEY and STRIPE_SECRET_KEY are set.\n' +
      'Use test keys (pk_test_... and sk_test_...) for testing.'
    );
  }

  if (!process.env.STRIPE_PUBLISHABLE_KEY.startsWith('pk_test_')) {
    throw new Error(
      'STRIPE TEST FAILED: STRIPE_PUBLISHABLE_KEY must be a test key (pk_test_...).\n' +
      'Do not use live keys for testing!'
    );
  }

  console.log('✓ Stripe credentials verified');
}

// Stripe test card numbers
const STRIPE_TEST_CARDS = {
  success: '4242424242424242',
  declined: '4000000000000002',
  insufficient_funds: '4000000000009995',
};

// Generate unique ID for this test run (supports high concurrency)
const testUniqueId = randomUUID();
const credentialsFile = join(process.cwd(), 'tmp', `test_credentials_${testUniqueId}.json`);

let credentials: TestCredentials;

test.describe('Stripe Payment Flow', () => {
  test.beforeAll(async () => {
    // Verify Stripe credentials before running any tests
    verifyStripeCredentials();

    // Seed test data with unique ID
    execSync(`TEST_UNIQUE_ID=${testUniqueId} bundle exec rails test_seeds:stripe_payment`, { stdio: 'inherit' });

    // Read credentials from file
    credentials = JSON.parse(readFileSync(credentialsFile, 'utf-8'));
  });

  test.afterAll(async () => {
    // Clean up credentials file
    if (existsSync(credentialsFile)) {
      unlinkSync(credentialsFile);
    }
  });

  test('completes Stripe payment and finalizes team', async ({ page }) => {
    // Step 1: Login as team captain
    await test.step('Login as team captain', async () => {
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
    });

    // Step 2: Navigate to team page
    await test.step('Navigate to team payments', async () => {
      await page.getByRole('link', { name: /races/i }).click();
      await page.getByText(credentials.race_name).first().click();
      await page.getByText(credentials.team_name).click();
      await page.waitForLoadState('networkidle');

      // Click Payments tab using JavaScript to ensure Bootstrap tab switching works
      await page.evaluate(() => {
        const tab = document.querySelector('a[href="#requirements"]') as HTMLElement;
        if (tab) tab.click();
      });
      await page.waitForTimeout(500);

      // Wait for the tab pane to have the 'active' class
      await expect(page.locator('#requirements.active')).toBeVisible({ timeout: 5000 });

      // Verify payment requirement is visible
      await expect(page.getByText('Registration Fee')).toBeVisible({ timeout: 5000 });
      await expect(page.locator('text=50.00').first()).toBeVisible();
    });

    // Step 3: Click the Stripe payment button and complete payment
    await test.step('Complete Stripe payment', async () => {
      // The Stripe Checkout button is injected by checkout.js
      // It creates a button with class "stripe-button-el"
      const stripeButton = page.locator('button.stripe-button-el, span:has-text("Pay with Card")').first();
      await expect(stripeButton).toBeVisible({ timeout: 10000 });

      // Click the Stripe button - this opens the Stripe Checkout popup
      await stripeButton.click();

      // Stripe Checkout (legacy) uses an iframe popup
      // Wait for the iframe to appear and get a frame locator
      const stripeIframe = page.frameLocator('iframe[name^="stripe_checkout"]').first();

      // Wait for the card number field to be visible
      // The Stripe Checkout form has fields for Email, Card number, MM/YY, and CVC
      const cardInput = stripeIframe.locator('input[placeholder="Card number"]');
      await expect(cardInput).toBeVisible({ timeout: 15000 });

      // Fill in email first (use type for character-by-character input)
      const emailInput = stripeIframe.locator('input[placeholder="Email"]');
      await emailInput.click();
      await emailInput.type(credentials.captain_email, { delay: 50 });

      // Fill in test card number (type slowly for Stripe validation)
      await cardInput.click();
      await cardInput.type(STRIPE_TEST_CARDS.success, { delay: 50 });

      // Fill in expiry date (MM/YY format) - use 12/34 as recommended by Stripe docs
      const expiryInput = stripeIframe.locator('input[placeholder="MM / YY"]');
      await expiryInput.click();
      await expiryInput.type('1234', { delay: 50 });

      // Fill in CVC (any 3 digits work)
      const cvcInput = stripeIframe.locator('input[placeholder="CVC"]');
      await cvcInput.click();
      await cvcInput.type('123', { delay: 50 });

      // Wait a moment for Stripe to validate the card
      await page.waitForTimeout(1000);

      // Submit the payment by clicking the Pay button
      const submitButton = stripeIframe.locator('button:has-text("Pay")');
      await submitButton.click();

      // Wait for the payment to process and redirect back
      // The app should show a success message: "Your card has been charged successfully."
      await expect(page.getByText(/Your card has been charged successfully|charged successfully/i)).toBeVisible({ timeout: 30000 });
    });

    // Step 4: Verify team finalized
    await test.step('Verify team finalization', async () => {
      // After successful payment, team should be finalized
      // Check for the congratulations banner
      await expect(page.locator('#congratulations-user-success')).toBeVisible({ timeout: 10000 });
    });
  });
});
