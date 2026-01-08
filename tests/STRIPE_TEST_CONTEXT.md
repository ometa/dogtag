# Stripe Payment Test - Context

## Current State
The Stripe payment integration test is **working** and passes successfully.

## Files

### 1. `lib/tasks/test_seeds.rake`
Task `test_seeds:stripe_payment` that:
- Creates captain user with unique email
- Creates race with unique name
- Creates **real PaymentRequirement** (not MockPaymentRequirement)
- Creates team with 5 people (full team)
- Writes credentials to `tmp/test_credentials_{uuid}.json`

### 2. `tests/stripe-payment.spec.ts`
Playwright test that:
- Verifies `.env` file exists with `STRIPE_PUBLISHABLE_KEY` and `STRIPE_SECRET_KEY`
- Fails immediately if Stripe credentials missing or not test keys (pk_test_...)
- Seeds test data via rake task
- Logs in as captain
- Navigates to team payments tab
- Clicks Stripe Checkout button
- Fills in test card details in Stripe iframe
- Submits payment
- Verifies success message and team finalization

## Test Card Details (from Stripe docs)
- **Card Number**: `4242424242424242`
- **Expiry**: Any future date (e.g., `12/34`)
- **CVC**: Any 3 digits (e.g., `123`)
- **Email**: Any valid email

## Running the Test
```bash
# Run just the Stripe test
npx playwright test stripe-payment.spec.ts --timeout=180000

# Run in headed mode to observe
npx playwright test stripe-payment.spec.ts --headed --timeout=180000
```

## Environment Requirements
- `.env` file with:
  ```
  STRIPE_PUBLISHABLE_KEY=pk_test_...
  STRIPE_SECRET_KEY=sk_test_...
  ```
- Rails server running on localhost:3000
- Redis running (for Sidekiq workers)

## Previous Issue (RESOLVED)

### Problem
The test was failing with an EPIPE error:
```
{"class":"Errno::EPIPE","reason":"Broken pipe @ rb_io_flush_raw - <STDOUT>"}
```

This caused the generic error message: "An error unrelated to processing your credit card has occured"

### Root Cause
Ruby's stdout was buffered. When the buffer tried to flush after the receiving pipe was closed (common in test environments with process spawning), it threw `Errno::EPIPE`.

### Solution
Added stdout/stderr sync to `config/boot.rb`:
```ruby
$stdout.sync = true
$stderr.sync = true
```

This disables buffering, so writes go directly without needing a flush operation that could fail.

## Related Files
- `app/controllers/charges_controller.rb` - handles payment
- `app/models/customer.rb` - Stripe customer management
- `app/models/payment_requirement.rb` - real Stripe requirement
- `app/models/team.rb` - finalize method queues Sidekiq worker
- `config/boot.rb` - stdout sync fix
