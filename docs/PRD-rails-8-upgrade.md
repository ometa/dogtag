# PRB: Upgrade Rails 7 to Rails 8

## Summary

Upgrade Dogtag from Rails 7.0 to Rails 8.0. This upgrade will bring performance improvements, new features, and ensure the application stays on a supported Rails version.

## Current State

- **Ruby Version**: 3.4.8
- **Rails Version**: ~> 7.0.0
- **Framework Defaults**: `config.load_defaults 7.0`
- **Database**: PostgreSQL 17
- **Background Jobs**: Sidekiq with Redis
- **Authentication**: Authlogic 6.x

## Prerequisites

Rails 8.0 requires **Ruby 3.2.0 or newer** (currently running 3.4.8 ✓)

## Upgrade Path

Per the Rails Upgrade Guide, we should upgrade incrementally:
1. Rails 7.0 → Rails 7.1
2. Rails 7.1 → Rails 7.2
3. Rails 7.2 → Rails 8.0

## Phase 1: Rails 7.0 → 7.1

### Configuration Changes Required

1. **Secret key base file rename**
   - File renamed from `tmp/development_secret.txt` to `tmp/local_secret.txt`
   - Action: Rename existing file or allow Rails to regenerate

2. **Autoload paths no longer in $LOAD_PATH**
   - Directories managed by autoloaders are no longer added to `$LOAD_PATH`
   - Action: Ensure no code uses manual `require` for autoloaded files

3. **Update autoload_lib configuration** (recommended)

   ```ruby
   # Replace current config:
   config.autoload_paths << Rails.root.join('lib')
   config.eager_load_paths << Rails.root.join('lib')

   # With:
   config.autoload_lib(ignore: %w(assets tasks))
   ```

4. **Rails.logger returns BroadcastLogger**
   - `ActiveSupport::Logger.broadcast` method removed
   - Action: Review any custom logger configurations

5. **show_exceptions configuration change**
   - Change `config.action_dispatch.show_exceptions = false` to `:none`
   - In `config/environments/test.rb`: Update to `:rescuable` or `:none`

6. **Connection pooling for cache stores**
   - `MemCacheStore` and `RedisCacheStore` now use connection pooling by default
   - Action: Review cache configuration if needed

### Gem Compatibility Check for 7.1

| Gem | Current Version | Rails 7.1 Compatible | Notes |
|-----|-----------------|----------------------|-------|
| authlogic | ~> 6.0 | ✓ | Verify |
| cancancan | ~> 3.0 | ✓ | |
| stripe | ~> 1.58.0 | ✓ | Very old, consider updating |
| sidekiq | * | ✓ | Verify version |
| haml-rails | * | ✓ | |
| kaminari | * | ✓ | |
| sass-rails | ~> 5.0 | ⚠️ | May need update |
| coffee-rails | * | ⚠️ | Deprecated, consider removal |

## Phase 2: Rails 7.1 → 7.2

### Configuration Changes Required

1. **Active Job queue adapter behavior change**
   - All tests now respect `config.active_job.queue_adapter`
   - Action: Verify test suite behavior with queue adapter settings

2. **alias_attribute bypasses custom methods**
   - `alias_attribute` now directly accesses database values
   - Action: Audit models for `alias_attribute` usage with custom methods

### Framework Defaults File

A `new_framework_defaults_7_2.rb` file will be created.

## Phase 3: Rails 7.2 → 8.0

### Configuration Changes Required

1. **Review release notes for breaking changes**
   - Rails 8.0 release notes should be reviewed for specific changes

2. **Update config.load_defaults**
   - Final step: change `config.load_defaults 7.0` to `8.0`

### New Features in Rails 8.0

- Built-in authentication generator
- Solid Queue, Solid Cache, Solid Cable (optional)
- Kamal deployment by default (optional)
- Propshaft as default asset pipeline (optional)

## Outstanding Framework Defaults

The following Rails 7.0 framework defaults in `config/initializers/new_framework_defaults_7_0.rb` should be reviewed and enabled before upgrading:

### High Priority (Enable Before Upgrade)
- [x] `button_to_generates_button_tag`
- [x] `apply_stylesheet_media_default`
- [x] `partial_inserts` (disabled by default in 7.0)
- [x] `raise_on_open_redirects`
- [x] `return_only_request_media_type_on_content_type`

### Medium Priority (Requires Data Migration)
- [x] `key_generator_hash_digest_class` - Requires cookie rotator
- [x] `hash_digest_class` - May invalidate caches/ETags
- [x] `cache_format_version` - Only after full deployment to 7.0

### Low Priority
- [x] `cookies_serializer` - Migrated to `:json`
- [x] `video_preview_arguments` - Only if using Active Storage video
- [x] `variant_processor` - Only if using Active Storage variants

## Cleanup Tasks

1. **Remove old framework defaults files**
   - `new_framework_defaults.rb`
   - `new_framework_defaults_5_1.rb`
   - `new_framework_defaults_5_2.rb`
   - `new_framework_defaults_6_0.rb`
   - `new_framework_defaults_6_1.rb`
   - `new_framework_defaults_7_0.rb` (after enabling all)

2. **Consider gem updates/removals**
   - `coffee-rails` - Deprecated, consider migrating to ES6
   - `ffi` version pin - Review if still needed
   - `stripe` - Update from 1.58.0 to modern version
   - `sass-rails` - Consider migration to modern CSS tooling

## Implementation Steps

### Step 1: Pre-upgrade Preparation
1. Ensure test suite passes completely
2. Review and enable remaining Rails 7.0 framework defaults
3. Clean up old framework defaults files
4. Review deprecation warnings in current app

### Step 2: Upgrade to Rails 7.1
1. Update Gemfile: `gem 'rails', '~> 7.1.0'`
2. Run `bundle update rails`
3. Run `bin/rails app:update`
4. Review and merge configuration changes
5. Update `config.load_defaults 7.1`
6. Run test suite, fix failures
7. Deploy and verify

### Step 3: Upgrade to Rails 7.2
1. Update Gemfile: `gem 'rails', '~> 7.2.0'`
2. Run `bundle update rails`
3. Run `bin/rails app:update`
4. Review and merge configuration changes
5. Update `config.load_defaults 7.2`
6. Run test suite, fix failures
7. Deploy and verify

### Step 4: Upgrade to Rails 8.0
1. Update Gemfile: `gem 'rails', '~> 8.0.0'`
2. Run `bundle update rails`
3. Run `bin/rails app:update`
4. Review and merge configuration changes
5. Update `config.load_defaults 8.0`
6. Run test suite, fix failures
7. Deploy and verify

## Risk Assessment

### High Risk Areas
- **Cookie/Session handling**: Digest class changes may invalidate sessions
- **Authlogic compatibility**: Verify 6.x works with Rails 8
- **Sidekiq integration**: Verify Active Job adapter behavior changes

### Medium Risk Areas
- **Asset pipeline**: `sass-rails`, `coffee-rails` compatibility
- **Caching**: Cache format and serialization changes
- **Third-party gems**: Some may need updates

### Low Risk Areas
- **Core application code**: Well-tested, follows conventions
- **Database**: PostgreSQL 17 fully supported
- **Ruby version**: Already on 3.4.8 (exceeds requirements)

## Rollback Plan

1. Keep database migrations backward compatible
2. Maintain ability to deploy previous commit
3. Test rollback procedure in staging environment
4. Do not remove deprecated code until fully migrated

## Testing Strategy

1. Run full RSpec suite after each upgrade phase
2. Run Playwright integration tests
3. Manual testing of critical paths:
   - User registration/login
   - Team creation
   - Payment processing
   - Admin functions
4. Performance testing to catch regressions

## Success Criteria

- [ ] All RSpec tests pass
- [ ] All Playwright tests pass
- [ ] No deprecation warnings
- [ ] `config.load_defaults 8.0` enabled
- [ ] All old framework defaults files removed
- [ ] Production deployment successful
- [ ] No user-facing issues reported

## Timeline Estimate

| Phase | Description |
|-------|-------------|
| Phase 1 | Rails 7.0 → 7.1 |
| Phase 2 | Rails 7.1 → 7.2 |
| Phase 3 | Rails 7.2 → 8.0 |
| Phase 4 | Cleanup and monitoring |

## Testing requirements

Both unit tests and integration tests need to pass.
Before beginning work, identify any obvious gaps in integration testing and suggest implementing them beforehand.
Any db migrations need to be tested against production data. Use the backup and local restore commands in CLAUDE.md to accomplish this step.

## References

- [Rails Upgrade Guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html)
- [Rails 8.0 Release Notes](https://guides.rubyonrails.org/8_0_release_notes.html)
- [Rails 7.2 Release Notes](https://guides.rubyonrails.org/7_2_release_notes.html)
- [Rails 7.1 Release Notes](https://guides.rubyonrails.org/7_1_release_notes.html)
