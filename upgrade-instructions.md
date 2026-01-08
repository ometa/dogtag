You are an expert senior computer science professor at a prestigious university. Your tenure is dependent upon you successfully upgrading this
   Ruby on Rails application from Ruby 2.7.8 to Ruby 3.1.7, and from Rails 5.2.8 to Rails 7.0. Failure is not an option. Use the test coverage
  to determine your success.

  ## Current State

  **Application Details:**
  - Ruby version: Currently 2.7.8 (target: 3.1.7)
  - Rails version: Currently 5.2.8 (target: 7.0)
  - Test suite: RSpec with 547 examples, 95.74% code coverage
  - Database: PostgreSQL
  - Current branch: `db/ruby3`

  **Baseline Test Results (Ruby 2.7.8 + Rails 5.2.8):**
  - 547 examples, 1 failure (pre-existing type conversion issue), 29 pending
  - 95.74% code coverage
  - Multiple keyword argument deprecation warnings (expected for Ruby 2.7)

  **Key Dependencies:**
  - activerecord-import
  - authlogic ~> 4.4.2
  - cancancan ~> 2.3.0
  - stripe ~> 1.58.0
  - sidekiq, sidekiq-cron, sidekiq-unique-jobs
  - newrelic_rpm
  - bootsnap
  - psych (currently locked to < 4 for Ruby 2.7 compatibility)

  ## What We've Discovered

  ### Attempted Direct Ruby 2.7 → 3.1 Upgrade Issues:

  1. **Psych 4.0 YAML Breaking Change**: Ruby 3.1 includes Psych 4.0 which uses `safe_load` by default and doesn't allow YAML anchors/aliases.
  Files affected:
     - `config/database.yml` (uses `&default` and `*default`)
     - `config/newrelic.yml` (uses `&default_settings` and `*default_settings`)

  2. **Keyword Arguments Separation**: Ruby 3.0+ enforces strict keyword argument separation. Rails 5.2 was built before this change and has
  compatibility issues in:
     - `ActiveRecord::Type.add_modifier`
     - `ActionDispatch::Static#initialize`
     - `ActiveModel::Type::Value#initialize`
     - `ActiveModel::Type::Integer#initialize`
     - `ActiveRecord::ConnectionAdapters::Transaction#initialize`
     - Many other internal Rails methods

  3. **Migration API Changes**: `ActiveRecord::Migration.check_pending!` signature changed

  ## Decided Upgrade Strategy

  After analysis, we determined that **Rails 7.0 is the minimum version** needed to properly support Ruby 3.1 without extensive monkey patching.

  **Upgrade Path:**
  Rails 5.2.8 + Ruby 2.7.8 (current)
    ↓
  Rails 6.0 + Ruby 2.7.8
    ↓
  Rails 6.1 + Ruby 2.7.8
    ↓
  Rails 7.0 + Ruby 2.7.8
    ↓
  Rails 7.0 + Ruby 3.1.7 (target)

  ## Your Mission

  Execute the complete upgrade following this plan:

  ### Phase 1: Baseline Verification
  1. Ensure you're on Ruby 2.7.8 and Rails 5.2.8
  2. Run full test suite to confirm 547 examples pass (1 pre-existing failure acceptable)
  3. Document current state

  ### Phase 2: Rails Upgrades (Keep Ruby 2.7.8)

  **For each Rails upgrade (6.0, then 6.1, then 7.0):**

  1. **Update Gemfile:**
     - Change Rails version
     - Update gem dependencies as needed
     - Check for deprecated gems

  2. **Run `rails app:update`:**
     - Review and merge configuration changes
     - Update initializers
     - Update environment configs

  3. **Bundle install:**
     - Resolve dependency conflicts
     - Update Gemfile.lock

  4. **Database migrations:**
     - Run `rails db:migrate`
     - Check schema.rb changes

  5. **Fix deprecations and breaking changes:**
     - Address deprecation warnings
     - Update code for API changes
     - Consult Rails upgrade guide sections for each version

  6. **Run full test suite:**
     - Fix failing tests
     - Ensure 95%+ code coverage maintained
     - All examples should pass (except 1 pre-existing failure)

  7. **Commit changes** before moving to next version

  ### Phase 3: Ruby Upgrade (Rails 7.0 stays)

  1. Update `.ruby-version` to `3.1.7`
  2. Update `Gemfile` ruby version to `3.1.7`
  3. Remove `psych < 4` constraint (Rails 7.0 handles this)
  4. Install Ruby 3.1.7: `rbenv install 3.1.7`
  5. Run `bundle install`
  6. Run full test suite - should pass cleanly on Rails 7.0

  ### Phase 4: Cleanup & Verification

  1. Verify no monkey patches remain in codebase
  2. Check that database.yml and newrelic.yml are clean
  3. Run full test suite multiple times with different seeds
  4. Test in development environment
  5. Document any remaining issues

  ## Critical Files

  **Configuration:**
  - `.ruby-version`
  - `Gemfile`
  - `config/application.rb`
  - `config/database.yml`
  - `config/newrelic.yml`

  **Reference Documents:**
  - Rails upgrade guide available in `rails-upgrade-guide.md`
  - Ruby 3.0 release notes in `ruby-3.0-released.md`
  - Ruby 3.1 release notes in `ruby-3.1-released.md`

  ## Success Criteria

  ✅ Ruby 3.1.7 installed and active
  ✅ Rails 7.0 installed and running
  ✅ All 547 test examples pass (1 pre-existing failure acceptable)
  ✅ 95%+ code coverage maintained
  ✅ No monkey patches in codebase
  ✅ Application boots successfully
  ✅ No deprecation warnings related to Ruby 3.1

  ## Important Notes

  - **Test frequently**: Run tests after each major change
  - **Commit incrementally**: Each Rails version upgrade should be its own commit
  - **Follow the upgrade guide**: Reference the rails-upgrade-guide.md for each version
  - **Don't skip versions**: Must go 5.2 → 6.0 → 6.1 → 7.0 in order
  - **Ruby upgrade comes last**: Only upgrade Ruby after Rails 7.0 is stable

  ## Ask Clarifying Questions

  If you encounter:
  - Ambiguous migration paths
  - Breaking changes with multiple solutions
  - Gem compatibility conflicts
  - Test failures you can't resolve

  Ask me before proceeding.

  Begin with Phase 1: Verify the baseline on Rails 5.2.8 + Ruby 2.7.8.
