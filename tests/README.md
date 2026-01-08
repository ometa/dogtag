# Dogtag Integration Tests with Playwright

This directory contains end-to-end integration tests for the Dogtag application using Playwright.

## Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Install Playwright Browsers

```bash
npx playwright install
```

## Running Tests

### Local Development

1. **Seed the test database:**

```bash
bundle exec rails test_seeds:basic
```

This creates:
- Admin user: `test+admin@example.com` / `password123`
- Captain user: `test+captain@example.com` / `password123`
- Fifth user: `test+fifth@example.com` / `password123`
- An open race
- A team with 4/5 people

2. **Run tests:**

```bash
# Run all tests (headless)
npm test

# Run tests in headed mode (see browser)
npm run test:headed

# Run tests in debug mode
npm run test:debug

# Run tests with UI mode (interactive)
npm run test:ui
```

### Against Staging or Production

Set the `BASE_URL` environment variable:

```bash
# Against staging
BASE_URL=https://dogtag-staging.herokuapp.com npm test

# Against production (be careful!)
BASE_URL=https://dogtag.herokuapp.com npm test
```

**Note:** Before running tests against deployed environments, seed the test data:

```bash
# Staging
heroku run rails test_seeds:basic -r staging

# Production (use with caution!)
heroku run rails test_seeds:basic -r heroku
```

## Test Structure

### Current Tests

- **`user-joins-team.spec.ts`**: Tests the happy path where a 5th user joins a team with 4 members, triggering team finalization.

### Writing New Tests

1. Create a new `.spec.ts` file in the `tests/` directory
2. Import Playwright test utilities:
   ```typescript
   import { test, expect } from '@playwright/test';
   ```
3. Write your test using `test.describe` and `test` blocks
4. Use `test.step` for clear test organization

Example:
```typescript
test.describe('Feature Name', () => {
  test('should do something', async ({ page }) => {
    await test.step('Step 1', async () => {
      await page.goto('/');
      // assertions
    });
  });
});
```

## Cleanup

After running tests, clean up test data:

```bash
# Local
bundle exec rails test_seeds:cleanup

# Staging
heroku run rails test_seeds:cleanup -r staging
```

## Debugging

### View Test Report

After running tests, view the HTML report:

```bash
npx playwright show-report
```

### Screenshots

Failed tests automatically capture screenshots in `test-results/`

### Traces

View trace files for failed tests:

```bash
npx playwright show-trace test-results/path-to-trace.zip
```

## CI/CD Integration

To run tests in CI:

```bash
# Install dependencies
npm ci
npx playwright install --with-deps

# Seed test data
bundle exec rails test_seeds:basic

# Run tests
npm test

# Cleanup
bundle exec rails test_seeds:cleanup
```

## Configuration

Edit `playwright.config.ts` to:
- Change test timeout
- Add more browsers (Firefox, Safari)
- Modify retry logic
- Configure reporters
- Set base URL

## Common Issues

### Port Already in Use

If port 3000 is already in use, Playwright will reuse the existing server.

### Test Data Conflicts

Always run `test_seeds:cleanup` between test runs to avoid data conflicts.

### Flaky Tests

Use Playwright's auto-waiting features. Avoid manual waits:

```typescript
// ❌ Bad
await page.waitForTimeout(1000);

// ✅ Good
await expect(page.getByText('Success')).toBeVisible();
```

## Resources

- [Playwright Documentation](https://playwright.dev)
- [Best Practices](https://playwright.dev/docs/best-practices)
- [Test Selectors](https://playwright.dev/docs/locators)
