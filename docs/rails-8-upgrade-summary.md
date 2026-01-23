# Rails 8.0 Upgrade Summary

**Completed:** 2026-01-23
**Upgraded From:** Rails 7.0.10 to Rails 8.0.4
**Ruby Version:** 3.4.8

## Overview

The Dogtag application was successfully upgraded from Rails 7.0 to Rails 8.0 via incremental upgrades (7.0 → 7.1 → 7.2 → 8.0). All 618 RSpec tests pass with 97.82% coverage, and all 3 Playwright integration tests pass.

## Commits

1. `254da37` - Clean up legacy framework defaults files
2. `c846a45` - Upgrade to Rails 7.1
3. `3f609f8` - Upgrade to Rails 7.2
4. `512d2b0` - Upgrade to Rails 8.0

## Key Changes Made

### Configuration Changes

| File | Change |
|------|--------|
| `Gemfile:43` | `gem 'rails', '~> 8.0.0'` |
| `config/application.rb:12` | `config.load_defaults 8.0` |
| `config/application.rb:14-15` | Replaced manual autoload paths with `config.autoload_lib(ignore: %w[assets tasks])` |
| `config/environments/test.rb:31` | Changed `show_exceptions = false` to `show_exceptions = :rescuable` |

### Secret Key Base Migration

Migrated `secret_key_base` from deprecated `config/secrets.yml` to environment config files:
- `config/environments/development.rb` - hardcoded development key
- `config/environments/test.rb` - hardcoded test key
- `config/environments/production.rb` - `ENV["SECRET_KEY_BASE"]`

The `config/secrets.yml` file was deleted.

### Deleted Files

Six legacy framework defaults files were removed (all either fully commented out or redundant with `config.load_defaults 7.0`):
- `config/initializers/new_framework_defaults.rb`
- `config/initializers/new_framework_defaults_5_1.rb`
- `config/initializers/new_framework_defaults_5_2.rb`
- `config/initializers/new_framework_defaults_6_0.rb`
- `config/initializers/new_framework_defaults_6_1.rb`
- `config/initializers/new_framework_defaults_7_0.rb`

### Deprecation Fixes (Rails 7.1)

- `ActiveRecord::Migration.check_pending!` → `check_all_pending!`
- `config.fixture_path` → `config.fixture_paths` (array)
- `serialize :metadata, JSON` → `serialize :metadata, coder: JSON`

### Test Updates (Rails 8.0)

Updated test assertion in `spec/controllers/charges_controller_spec.rb` for Rails 8.0 error message format change:
- Old: `"param is missing or the value is empty: #{param}"`
- New: `"param is missing or the value is empty or invalid: #{param}"`

---

## Issues to Investigate

### 1. Session/Cookie Handling Changes

**Risk Level:** Medium

Rails 8.0 includes changes to session and cookie handling. While all tests pass, monitor production for:
- Session expiration issues
- Cookie serialization problems (if users have old cookies)
- CSRF token validation failures

**Recommended Action:** Monitor error tracking (Rollbar) after deployment for any `ActionController::InvalidAuthenticityToken` or session-related errors.

### 2. Authlogic Compatibility

**Risk Level:** Medium

Authlogic 6.x was originally designed for Rails 6.0+. While it works with Rails 8.0 in tests:
- The gem has not been updated since 2023
- Session persistence mechanisms may have subtle behavior changes
- Password reset flows (perishable tokens) should be manually tested

**Recommended Action:**
- Manually test login/logout flows in staging
- Test password reset flow end-to-end
- Consider adding Playwright tests for user registration and password reset flows
- Long-term: evaluate migration to Rails built-in authentication (Rails 8.0 feature)

### 3. `belongs_to` Required by Default

**Risk Level:** Low

Rails 8.0 enforces `belongs_to_required_by_default = true`. Two models have `belongs_to` without explicit `optional: true`:
- `Tier.belongs_to :requirement`
- `Person.belongs_to :team`

Both were analyzed and are safe because:
- Tiers are always created through requirements (never orphaned)
- People are always created through teams (never orphaned)

**Recommended Action:** No action needed, but document this for future model additions.

### 4. Active Job Queue Adapter Behavior

**Risk Level:** Low

Rails 7.2+ changed how tests respect queue adapter settings. The test suite uses `GoodJob Inline Adapter` by default with `:active_job` option for test adapter.

**Recommended Action:** If adding new background job tests, verify they use the correct adapter.

### 5. `alias_attribute` Behavior Change

**Risk Level:** Low

Rails 7.2 changed `alias_attribute` to bypass custom getter/setter methods. A grep for `alias_attribute` usage should be done if any issues arise.

**Recommended Action:** Only investigate if attribute-related bugs appear.

---

## Risks

### Production Deployment Risks

1. **Cookie/Session Invalidation**
   - Users may need to re-login after deployment
   - Old session cookies may not deserialize correctly
   - Mitigation: Deploy during low-traffic period

2. **Caching Behavior**
   - `cache_format_version` changed between Rails versions
   - May cause cache misses initially
   - Mitigation: Pre-warm caches after deployment if needed

3. **Stripe Integration**
   - Stripe gem (`~> 1.58.0`) is very old (current is 13.x)
   - While it works, consider upgrading separately
   - The `stripe-ruby-mock` test gem is also outdated

### Technical Debt Created

1. **Stripe gem version** - Running a 7+ year old version
2. **Authlogic** - Consider migration to Rails 8 built-in auth generator
3. **Asset pipeline** - Still using Sprockets; consider Propshaft or import maps

---

## Verification Checklist

Before production deployment:

- [ ] Test against production database backup locally:
  ```bash
  heroku pg:backups:capture --app dogtag
  curl -o file.dump `heroku pg:backups:url --app dogtag`
  pg_restore --verbose --clean --no-acl --no-owner -h localhost -d dogtag_development file.dump
  bundle exec rails db:migrate
  ```

- [ ] Deploy to staging first:
  ```bash
  git push staging db/rails8:main
  heroku run rails db:migrate -a staging-app-name
  ```

- [ ] Manual smoke tests on staging:
  - [ ] User login/logout
  - [ ] User registration (new account)
  - [ ] Password reset flow
  - [ ] Team creation
  - [ ] Payment flow (test mode)
  - [ ] Join team flow

- [ ] Monitor Rollbar after production deployment for:
  - Session errors
  - CSRF errors
  - Serialization errors

---

## Future Recommendations

1. **Add Integration Tests** - The PRD identified gaps in integration test coverage:
   - User registration flow
   - Password reset flow
   - These would catch Authlogic-related regressions

2. **Upgrade Stripe** - The current Stripe gem is significantly outdated

3. **Evaluate Rails 8 Features** - Consider adopting:
   - Built-in authentication generator (replace Authlogic)
   - Solid Queue (if moving away from Sidekiq)

4. **Keep Rails Updated** - Follow the same incremental upgrade pattern for future Rails releases
