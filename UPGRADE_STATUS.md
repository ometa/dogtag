# Ruby & Rails Upgrade Status - Context Preservation

## Current State: UPGRADE COMPLETE, TESTS NEED FIXING

### Versions Achieved ✅
- **Ruby**: 2.7.8 → 3.1.7 ✅
- **Rails**: 5.2.8 → 7.0.10 ✅
- **Branch**: `db/ruby3`
- **Application**: Boots successfully ✅
- **YAML Anchors**: Working (Psych 4.0 issue resolved) ✅

### Test Status ⚠️
```
Current:  547 examples, 43 failures, 29 pending, 94.7% coverage
Baseline: 547 examples,  1 failure,  29 pending, 95.74% coverage
Delta:    42 additional failures need fixing
```

### Commits Made
1. `e727404` - Upgrade to Rails 6.0.6.1 (3 failures)
2. `80735e0` - Upgrade to Rails 6.1.7.10 (15 failures)
3. `689885d` - Upgrade to Rails 7.0.10 (43 failures)
4. `ad94716` - Upgrade to Ruby 3.1.7 (43 failures - no regression)

---

## NEXT STEPS: Fix All Test Failures

### Priority 1: Categorize Failures
Run this command to get detailed failure list:
```bash
bundle exec rspec --format failures --failure-exit-code 0 2>/dev/null | grep "^\./" | sort | uniq
```

### Known Failure Categories (from previous analysis):

#### 1. **Uniqueness Validation Failures (4 failures)**
- `spec/models/person_spec.rb:108` - fails if team is already full
- `spec/models/person_spec.rb:25` - prevents updating
- `spec/models/tier_spec.rb:49` - fails when another tier has same "price"
- `spec/models/tier_spec.rb:43` - fails when another tier has same "begin_at"

**Issue**: Rails 7.0 changed uniqueness validation behavior. Tests expect validation to fail but records are being saved as valid.

**Investigation needed**: Check if uniqueness validation scopes changed in Rails 7.0.

#### 2. **User Validation Failures (~6 failures)**
- `spec/controllers/users_controller_spec.rb:75` - multiple instances
- Related to password/password_confirmation validation messages

**Issue**: Authlogic 6.x changed validation behavior. Error messages differ from expected.

**Status**: Minor edge cases, acceptable but should be fixed if possible.

#### 3. **Controller Action Failures (~30+ failures)**
- Charges controller (5 failures)
- Races controller failures
- People controller failures
- Teams controller failures (caching, etc.)

**Investigation needed**: Run individual controller specs to identify patterns.

#### 4. **Pre-existing Failure (1 - acceptable)**
- `spec/workers/classy_create_fundraising_team_spec.rb:132` - classy_id type conversion (integer vs string)

---

## Key Code Changes Made

### 1. Authlogic 4.4.2 → 6.5.0
```ruby
# app/models/user.rb changes:
- c.validate_login_field = false  # Removed (doesn't exist in 6.x)
+ validates_confirmation_of :password, if: :require_password?  # Added
```

### 2. CanCanCan 2.3.0 → 3.6.1
- Updated for Rails 6.0+ compatibility
- Fixes "model adapter does not support fetching records" error

### 3. update_attributes → update
```ruby
# Replaced in 2 files (Rails 6.1 removed update_attributes):
- app/controllers/application_controller.rb:81
- app/controllers/teams_controller.rb:113
```

### 4. Gemfile Changes
```ruby
# Added:
gem 'scrypt'  # Required by authlogic 6.x
gem 'json-schema', '< 6.0'  # v6+ requires Ruby 3.2+

# Removed:
gem 'psych', '< 4'  # No longer needed with Ruby 3.1.7
gem 'logger', '~> 1.6.0'  # No longer needed with Ruby 3.1.7
gem 'rdoc', '~> 6.3.3'  # No longer needed with Ruby 3.1.7
```

### 5. Config Changes
```ruby
# config/application.rb:
config.load_defaults 7.0
config.autoload_paths << Rails.root.join('lib')
config.eager_load_paths << Rails.root.join('lib')

# config/environments/production.rb:
config.force_ssl = true  # Re-enabled (moved from controller)

# config/boot.rb:
require 'bootsnap/setup'  # Re-enabled (works with Ruby 3.1.7)
```

---

## Critical Files (routes.rb, locales/en.yml)

**IMPORTANT**: `rails app:update` kept overwriting these files. They were restored from git multiple times:

```bash
# If they get overwritten again:
git checkout config/routes.rb config/locales/en.yml
```

### config/routes.rb
Contains all application routes. Was completely wiped by app:update.

### config/locales/en.yml
Contains custom i18n translations (e.g., `at: "at"`). Was wiped by app:update.

---

## Running Tests

### Full test suite:
```bash
bundle exec rspec --format progress
```

### With coverage:
```bash
bundle exec rspec --format progress 2>&1 | grep "examples,"
bundle exec rspec --format progress --failure-exit-code 0 2>&1 | tail -5
```

### Specific categories:
```bash
# Models only (currently 4 failures):
bundle exec rspec spec/models/ --format progress

# Controllers only (currently ~39 failures):
bundle exec rspec spec/controllers/ --format progress

# Single test with details:
bundle exec rspec spec/models/tier_spec.rb:43 --format documentation
```

### Failure details:
```bash
# Get list of failing test locations:
bundle exec rspec --format failures --failure-exit-code 0 2>/dev/null | grep "^\./"

# Get detailed failure output:
bundle exec rspec --format documentation --failure-exit-code 0 2>&1 | less
```

---

## Investigation Strategy

### Step 1: Fix Model Validation Failures (4 failures)
These are the most fundamental. Start here.

1. **Run the failing uniqueness validation tests**:
```bash
bundle exec rspec spec/models/tier_spec.rb:43 --format documentation
bundle exec rspec spec/models/tier_spec.rb:49 --format documentation
bundle exec rspec spec/models/person_spec.rb:25 --format documentation
bundle exec rspec spec/models/person_spec.rb:108 --format documentation
```

2. **Check the model files**:
- `app/models/tier.rb` - Check uniqueness validations
- `app/models/person.rb` - Check validations

3. **Rails 7.0 uniqueness validation changes**:
Research if Rails 7.0 changed how `validates_uniqueness_of` with scope works.
Possible issue: https://github.com/rails/rails/pull/43688

### Step 2: Fix Controller Failures (~39 failures)

1. **Identify common patterns**:
```bash
# Get all controller failures:
bundle exec rspec spec/controllers/ --format failures --failure-exit-code 0 2>/dev/null | head -50
```

2. **Check for common issues**:
- Parameter handling changes in Rails 7.0
- Flash message format changes
- Redirect behavior changes
- Session handling changes

3. **Test one controller at a time**:
```bash
bundle exec rspec spec/controllers/charges_controller_spec.rb --format documentation
bundle exec rspec spec/controllers/teams_controller_spec.rb --format documentation
```

### Step 3: Fix User Validation Edge Cases (6 failures)

These are lower priority as they're edge cases in password validation.

```bash
bundle exec rspec spec/controllers/users_controller_spec.rb:75 --format documentation
```

---

## Rails 7.0 Deprecations to Watch For

1. **`update_attributes` removed** ✅ Already fixed
2. **Uniqueness validation behavior** ⚠️ Needs investigation
3. **`ActiveRecord::Base.connection.clear_query_cache`** - May have changed
4. **Belongs_to required by default** - May affect tests
5. **Autoloading changes** - Zeitwerk is now default ✅ Already configured

---

## Rails 7.0 Upgrade Guide References

Key sections from `rails-upgrade-guide.md`:
- Line 198: "Upgrading from Rails 7.0 to Rails 7.1" (for future reference)
- Check for Rails 6.1 → 7.0 specific breaking changes

Search the guide:
```bash
grep -A 10 "Upgrading from Rails 6.1 to Rails 7.0" rails-upgrade-guide.md
```

---

## Database & Schema

### Migrations run:
- Active Storage migrations for Rails 6.1 (2 migrations)
- Active Storage migration for Rails 7.0 (1 migration)

### Schema status:
```bash
bundle exec rails db:migrate:status
```

All migrations are up. No pending migrations.

---

## Files Modified (Important Ones)

### Models:
- `app/models/user.rb` - Authlogic 6.x API changes

### Controllers:
- `app/controllers/application_controller.rb` - Removed force_ssl, updated update_attributes
- `app/controllers/teams_controller_spec.rb` - Updated update_attributes

### Config:
- `config/application.rb` - load_defaults 7.0, lib/ autoload paths
- `config/boot.rb` - Re-enabled bootsnap
- `config/environments/production.rb` - Re-enabled force_ssl
- `config/routes.rb` - Restored multiple times
- `config/locales/en.yml` - Restored multiple times

### Gem-related:
- `Gemfile` - Updated Rails, authlogic, cancancan, added scrypt, locked json-schema
- `.ruby-version` - Updated to 3.1.7

---

## Testing Commands Quick Reference

```bash
# Quick model test to verify setup:
bundle exec rspec spec/models/team_spec.rb:24 --format documentation

# Full run with summary:
bundle exec rspec --format progress 2>&1 | grep "examples,"

# Get coverage:
bundle exec rspec --format progress --failure-exit-code 0 2>&1 | tail -5

# All failures with details:
bundle exec rspec --format documentation --failure-exit-code 0 > test_failures.txt 2>&1

# Specific failure investigation:
bundle exec rspec spec/models/tier_spec.rb:43 --format documentation 2>&1 | tail -30
```

---

## Success Criteria

To complete this upgrade, we need:

- [ ] **547 examples, 1 failure** (the pre-existing classy_id issue), 29 pending
- [ ] **95%+ code coverage** (currently at 94.7%, baseline was 95.74%)
- [ ] **All new failures fixed** (currently 42 additional failures)

---

## Environment Details

- **Ruby**: 3.1.7p261 (2025-03-26 revision 0a3704f218) [arm64-darwin25]
- **Rails**: 7.0.10
- **Bundler**: 2.1.4
- **Database**: PostgreSQL
- **Working Directory**: `/Users/devin/repo/dogtag`
- **Branch**: `db/ruby3`

---

## Notes & Observations

1. **Bootsnap works**: Now that we're on Ruby 3.1.7, bootsnap works without issues.

2. **YAML anchors work**: The original Psych 4.0 issue is resolved. `config/database.yml` and `config/newrelic.yml` use YAML anchors (`&default`, `*default`) and they work correctly.

3. **No monkey patches needed**: Clean upgrade without hacks or workarounds.

4. **Test regression pattern**:
   - Rails 6.0: 3 failures (excellent)
   - Rails 6.1: 15 failures (acceptable)
   - Rails 7.0: 43 failures (needs fixing)
   - Ruby 3.1.7: 43 failures (no regression from Ruby upgrade)

5. **Model tests mostly pass**: 163 examples, only 4 failures. The issue is primarily in uniqueness validations.

6. **Controller tests have the most failures**: ~39 failures in controller specs. This suggests a systematic issue with how controllers are tested in Rails 7.0.

---

## Quick Start for New Session

```bash
cd /Users/devin/repo/dogtag
git status  # Should be on db/ruby3 branch
ruby -v     # Should show 3.1.7
bundle exec rails -v  # Should show 7.0.10

# Run tests to see current state:
bundle exec rspec --format progress 2>&1 | grep "examples,"

# Start investigating failures:
bundle exec rspec spec/models/ --format documentation --failure-exit-code 0 > model_failures.txt 2>&1
bundle exec rspec spec/controllers/ --format failures --failure-exit-code 0 2>/dev/null | head -50
```

---

## END OF CONTEXT PRESERVATION

**Next Action**: Begin systematic investigation and fixing of the 42 test failures, starting with the 4 model uniqueness validation failures as they are most fundamental.
