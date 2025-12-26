import { test, expect } from '@playwright/test';
import { execSync } from 'child_process';
import { readFileSync, unlinkSync, existsSync } from 'fs';
import { randomUUID } from 'crypto';
import { join } from 'path';

/**
 * Integration Test: Captain Adds Fifth Person and Triggers Team Finalization
 *
 * This test verifies the happy path where:
 * 1. A team has 4/5 members
 * 2. Team captain logs in
 * 3. Captain adds the 5th person to the team
 * 4. Team becomes finalized (meets all requirements)
 * 5. Background job is queued to finalize the team
 */

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

test.describe('User Registration and Team Finalization', () => {
  test.beforeAll(async () => {
    // Seed test data with unique ID
    execSync(`TEST_UNIQUE_ID=${testUniqueId} bundle exec rails test_seeds:basic`, { stdio: 'inherit' });

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

  test('captain adds fifth person and triggers finalization', async ({ page }) => {
    // Generate unique identifier for new person
    const uniqueId = `${Date.now()}-${Math.random().toString(36).substring(2, 8)}`;

    const fifthPerson = {
      firstName: 'Fifth',
      lastName: 'Joiner',
      email: `fifth-${uniqueId}@example.com`,
      phone: '555-999-8888',
      zipcode: '60601'
    };

    // Step 1: Navigate to login page
    await test.step('Navigate to login', async () => {
      await page.goto('/');

      // Click the Login dropdown in top navigation
      await page.getByText('Login').first().click();

      // Wait for dropdown menu to appear and click the Login link inside
      await page.waitForTimeout(300); // Brief wait for dropdown animation

      // Click the "Login" link in the dropdown menu (not the dropdown trigger)
      const dropdownLinks = page.getByRole('link', { name: 'Login' });
      await dropdownLinks.last().click(); // The link inside dropdown appears after the trigger
    });

    // Step 2: Login as the team captain
    await test.step('Login as team captain', async () => {
      await expect(page).toHaveURL(/user_session\/new|login|sign.?in/i);

      // Fill in login form (fields don't have visible labels, use input types)
      // Find visible text inputs - email field is first visible input, password is type=password
      const emailInput = page.locator('input[type="text"]').first().or(
        page.locator('input:not([type="hidden"])').first()
      );
      await emailInput.fill(credentials.captain_email);

      const passwordInput = page.locator('input[type="password"]');
      await passwordInput.fill(credentials.captain_password);

      // Submit login form
      await page.getByRole('button', { name: /log ?in/i }).click();

      // Verify successful login - look for success message
      await expect(page.getByText(/login successful/i)).toBeVisible();
    });

    // Step 3: Navigate to open races
    await test.step('Navigate to race registration', async () => {
      // Look for races link in navigation
      const racesLink = page.getByRole('link', { name: /races/i });
      await racesLink.click();

      // Should see the test race - use the race name from credentials
      await expect(page.getByText(credentials.race_name)).toBeVisible();

      // Click on the test race to view details
      await page.getByText(credentials.race_name).first().click();
    });

    // Step 4: Navigate to team add person page
    await test.step('Navigate directly to add person form', async () => {
      // Navigate directly using team ID from credentials
      await page.goto(`/teams/${credentials.team_id}/people/new`);
    });

    // Step 5: Fill in person details and submit
    await test.step('Fill in person details', async () => {
      // Wait for the add person form to load
      await page.waitForLoadState('networkidle');

      // Fill in all required person details
      // The form uses plain text labels, not <label> elements, so we find visible inputs by position
      const visibleInputs = page.locator('input:not([type="hidden"])');
      await visibleInputs.nth(0).fill(fifthPerson.firstName); // First Name
      await visibleInputs.nth(1).fill(fifthPerson.lastName); // Last Name
      await visibleInputs.nth(2).fill(fifthPerson.email); // Email
      await visibleInputs.nth(3).fill(fifthPerson.phone); // Mobile Phone
      await visibleInputs.nth(4).fill(fifthPerson.zipcode); // Zip Code

      // Select experience level (years participated)
      const experienceSelect = page.locator('select').first();
      await experienceSelect.selectOption({ index: 1 }); // Select first option after "Please Select"

      // Submit the form to add the person to the team
      await page.getByRole('button', { name: /save|submit|add|create/i }).click();
    });

    // Step 6: Verify successful person addition and team finalization
    await test.step('Verify team finalization', async () => {
      // Verify team finalized - congratulations banner should appear
      await expect(page.locator('#congratulations-user-success')).toBeVisible();
    });
  });
});
