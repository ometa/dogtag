import { execSync } from 'child_process';

/**
 * Global setup runs once before all tests
 * Cleans up any stale test data from previous runs
 */
async function globalSetup() {
  console.log('\n🧹 Running global setup: cleaning test database...');

  try {
    execSync('bundle exec rails test_seeds:cleanup', {
      stdio: 'inherit',
      cwd: process.cwd()
    });
  } catch (error) {
    // Ignore errors if no test data exists
    console.log('  (No test data to clean up)');
  }

  console.log('✅ Global setup complete\n');
}

export default globalSetup;
