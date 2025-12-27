# Dogtag - Rails 7.0 Upgrade: Production Deployment Context

**Last Updated**: 2025-12-26 21:52 CST
**Branch**: `db/ruby3`
**Current HEAD**: `b4ef458`
**Status**: ✅ **STAGING DEPLOYED - Monitoring for 24h before production**

---

## ⚠️ CRITICAL: Read This First

You are a prestigious computer science engineer at Oxford University. Your tenure depends on the **successful deployment** of this Rails application:
1. First to **staging** (dogtag-staging on Heroku)
2. Then to **production** (dogtag on Heroku)

### Required Behaviors for Success

**METHODICAL APPROACH**
- Always verify current state before making changes
- Run tests before and after ANY modification
- Never assume - always check logs, test output, and deployment status
- Document every significant decision

**DEPLOYMENT DISCIPLINE**
- Never force push to production
- Always deploy to staging first and validate thoroughly
- Monitor Heroku logs during and after deployment
- Have rollback plan ready before any deploy
- Test critical user paths on staging before promoting to production

**COMMUNICATION**
- Be explicit about risks and trade-offs
- Ask clarifying questions when requirements are ambiguous
- Provide clear status updates with concrete data (test counts, error rates, etc.)
- Never say "should work" - verify and report actual results

**FAILURE HANDLING**
- If deployment fails, investigate root cause before retry
- Check Heroku logs, build output, and application logs
- Never apply blind fixes - understand the problem first
- Document failures and solutions for future reference

---

## Approved Commands (Auto-Execute Without Confirmation)

**Git Commands in `/Users/devin/repo/dogtag`**:
- ✅ `git push staging <branch>:main` - Deploy to staging (force push allowed)
- ✅ `git push staging <branch>:main --force` - Force push to staging
- ✅ All other git commands (status, log, diff, fetch, etc.)
- ⚠️ `git push heroku <branch>:main` - **REQUIRES EXPLICIT CONFIRMATION** (production deploy)

**Heroku Commands**:
- ✅ All `heroku` commands are approved (logs, ps, config, addons, releases, run, etc.)
- ✅ Heroku commands for staging remote (`-r staging`)
- ✅ Heroku commands for production remote (`-r heroku`)
- ⚠️ Note: Production deploys (`git push heroku`) still require confirmation per above

**General**:
- ✅ Read, Write, Edit operations on code files
- ✅ Bash commands for development/testing (bundle, rails, rspec, etc.)

**Last Updated**: 2025-12-26 (During staging deployment)

---

## Current State

### Versions
- **Ruby**: 2.7.8 → **3.1.7** ✅ (Deployed to local, ready for Heroku)
- **Rails**: 5.2.8 → **7.0.10** ✅ (Fully tested, 3 acceptable failures)
- **Heroku Stack**: heroku-24 (configured on staging, activates on next deploy)

### Test Results
```
RSpec: 547 examples, 0 failures, 29 pending ✅
Playwright: 3 passed (integration tests)
Coverage: 95.73%
```

**All Tests Passing!**

**Fixed This Session**:
- ✅ `spec/workers/classy_create_fundraising_team_spec.rb:132` - Fixed classy_id type consistency
- ✅ Changed teams.classy_id from string to integer (migration + code updates)

---

## Upgrade History (Commits on db/ruby3)

### Core Upgrade Commits
1. `e727404` - Upgrade to Rails 6.0.6.1 (547 examples, 3 failures)
2. `80735e0` - Upgrade to Rails 6.1.7.10 (547 examples, 15 failures)
3. `689885d` - Upgrade to Rails 7.0.10 (547 examples, 43 failures)
4. `ad94716` - Upgrade to Ruby 3.1.7 (547 examples, 43 failures - no regression)
5. `26b5369` - Fix Rails 7.0 test failures (547 examples, 3 failures)

### Recent Commits (This Session)
6. `c1a6b04` - Configure Playwright for sequential test execution with auto server
7. `bae96fb` - Add Ruby 3.1.7 to CircleCI test matrix
8. `7cba95f` - Fix classy_id type consistency for Ruby 3.1 compatibility
9. `b4ef458` - Change teams.classy_id from string to integer ⭐ **Current HEAD**

### What Was Fixed
**Rails 7.0 Breaking Changes (All Resolved)**:
- Updated error syntax in validators (`errors.add()` API)
- Fixed template paths (removed `.html.erb` extensions)
- Fixed association reloading in TierValidator
- Updated test mocks for removed methods (`update_attributes` → `update`)
- Changed redirect test to use internal URLs only (security best practice)

**Ruby 3.1 Compatibility**:
- Fixed classy_id type coercion (explicit `.to_s` for string columns)
- Factory updated to use string values for classy_id

**No shortcuts remain - all fixes are proper and production-ready.**

---

## Heroku Deployment Configuration

### Compatibility Matrix ✅
| Component | Version | Heroku-24 Status |
|-----------|---------|------------------|
| Ruby | 3.1.7 | ✅ Supported (3.0+) |
| Rails | 7.0.10 | ✅ Supported (6.0+) |
| PostgreSQL | (via pg gem) | ✅ Compatible |
| Unicorn | (web server) | ✅ Compatible |
| Sidekiq | (worker) | ✅ Compatible |
| Buildpack | heroku/ruby | ✅ Standard |

### Heroku Remotes (Verified)
```
staging   → https://git.heroku.com/dogtag-staging.git (heroku-24 active on next deploy)
heroku    → https://git.heroku.com/dogtag.git (production)
dogtag-22 → https://git.heroku.com/dogtag-22.git (legacy)
```

### Procfile Configuration
```
web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker: bundle exec sidekiq -C ./config/sidekiq.yml
```

---

## DEPLOYMENT PROCEDURE

### Phase 1: Deploy to Staging ⬅️ **START HERE**

**Pre-Deployment Checklist**:
- [x] All tests passing (except 3 acceptable failures)
- [x] Code committed to db/ruby3 branch
- [x] Heroku-24 compatibility verified
- [x] No security vulnerabilities
- [ ] **Ready to deploy**

**Deployment Commands**:
```bash
# 1. Verify you're on the right branch
git branch --show-current  # Should show: db/ruby3

# 2. Verify commit is latest
git log --oneline -1  # Should show: 26b5369

# 3. Push to staging
git push staging db/ruby3:main

# 4. IMMEDIATELY monitor deployment
heroku logs --tail -r staging

# 5. Wait for build to complete - watch for:
#    - "Verifying deploy... done."
#    - OR any errors in build process
```

**Post-Deployment Validation**:
```bash
# 1. Check app status
heroku ps -r staging
# Expected: web.1, worker.1 (both "up")

# 2. Check for migrations (if any pending)
heroku run rails db:migrate:status -r staging
# Run migrations ONLY if needed:
# heroku run rails db:migrate -r staging

# 3. Test the app
heroku open -r staging
# Manually verify:
# - App loads (homepage)
# - Can login/logout
# - Core features work

# 4. Monitor logs for errors
heroku logs --tail -r staging
# Watch for 5-10 minutes for any errors

# 5. Check for any crashes
heroku ps -r staging
# All dynos should show "up"
```

**Critical Success Criteria for Staging**:
- [ ] App deploys without build errors
- [ ] App boots successfully (no crashes in logs)
- [ ] Homepage accessible
- [ ] User authentication works (login/logout)
- [ ] No error 500s in logs during testing
- [ ] Background workers processing (if applicable)
- [ ] Database connections working

**IF STAGING FAILS**:
1. DO NOT proceed to production
2. Check `heroku logs --tail -r staging` for errors
3. Check `heroku releases -r staging` to see what happened
4. Rollback if needed: `heroku rollback -r staging`
5. Fix the issue locally, test, commit, and retry

---

### Phase 2: Deploy to Production (ONLY After Staging Success)

**Pre-Production Checklist**:
- [ ] Staging has been running successfully for at least 24 hours
- [ ] All critical user paths tested on staging
- [ ] Stakeholder approval received
- [ ] Rollback plan documented
- [ ] Maintenance window scheduled (if needed)

**Production Deployment Commands**:
```bash
# 1. Verify staging is stable
heroku ps -r staging
heroku logs --tail -r staging  # Check for recent errors

# 2. Check production current state
heroku releases -r heroku
heroku ps -r heroku

# 3. Deploy to production
git push heroku db/ruby3:main

# 4. IMMEDIATELY monitor
heroku logs --tail -r heroku

# 5. Post-deploy validation (same as staging)
heroku ps -r heroku
heroku open -r heroku
```

**Production Rollback (If Needed)**:
```bash
# Check recent releases
heroku releases -r heroku

# Rollback to previous version
heroku rollback -r heroku

# Verify rollback success
heroku ps -r heroku
heroku logs --tail -r heroku
```

---

## Common Issues & Solutions

### Issue: Build Fails with "Ruby version not found"
**Solution**: Ensure `.ruby-version` file contains `3.1.7` and is committed

### Issue: Missing gems during build
**Solution**: Run `bundle install` locally, commit `Gemfile.lock`, retry deploy

### Issue: Database migration errors
**Solution**: Check `heroku run rails db:migrate:status -r staging` and run pending migrations

### Issue: App crashes on boot
**Solution**:
1. Check `heroku logs --tail -r staging` for error details
2. Common causes: missing ENV vars, database connection issues, missing gems
3. Verify all required ENV vars are set: `heroku config -r staging`

### Issue: "Couldn't find that process type"
**Solution**: Verify Procfile is committed and correctly formatted

---

## Testing Commands (Local)

```bash
# Full RSpec test suite
bundle exec rspec --format progress

# Quick status check
bundle exec rspec --format progress 2>&1 | tail -5

# Test specific areas
bundle exec rspec spec/models/ --format progress
bundle exec rspec spec/controllers/ --format progress

# Playwright integration tests (auto-starts server on port 3099)
npm run test

# Verify versions
ruby -v           # Should show 3.1.7
bundle exec rails -v    # Should show 7.0.10
```

---

## CI/CD Configuration

### CircleCI
- **Config**: `.circleci/config.yml`
- **Ruby versions tested**: 2.7.8, 3.1.7 (matrix build)
- **Database**: PostgreSQL 14.6

### Playwright Integration Tests
- **Config**: `playwright.config.ts`
- **Tests**: `tests/*.spec.ts`
- **Port**: 3099 (auto-started WEBrick server)
- **Execution**: Sequential (workers: 1) - WEBrick is single-threaded
- **Global setup**: Cleans database before test suite

---

## Key Technical Details

### Rails 7.0 Breaking Changes (All Fixed)
1. ✅ Error API: `errors[:field] << 'msg'` → `errors.add(:field, 'msg')`
2. ✅ Template paths: Can't include file extensions in `render template:`
3. ✅ Redirects: External redirects require explicit opt-in (we use internal only)
4. ✅ Associations: Reloading behavior requires explicit `.reload`
5. ✅ Removed methods: `update_attributes` → `update`
6. ✅ Cache-Control: Header format simplified

### Security Posture
- ✅ No open redirect vulnerabilities (internal redirects only)
- ✅ No `allow_other_host: true` bypasses
- ✅ Session management follows Rails 7.0 best practices
- ✅ All validator logic properly scoped

### Modified Files (in commit 26b5369)
**Application Code**:
- `app/validators/tier_validator.rb` - Error syntax + association handling
- `app/validators/person_validator.rb` - Error syntax
- `app/models/person.rb` - Validator lifecycle
- `app/controllers/application_controller.rb` - Template paths
- `app/controllers/charges_controller.rb` - Error message parsing

**Test Code**:
- `spec/controllers/people_controller_spec.rb` - Mock method updates
- `spec/controllers/teams_controller_spec.rb` - Cache header expectations
- `spec/controllers/user_sessions_controller_spec.rb` - Internal redirect testing

---

## Success Metrics

### Deployment Success Criteria
- [x] Local tests passing (95.72% coverage, 3 acceptable failures)
- [x] Code committed and ready
- [x] Heroku-24 compatibility verified
- [x] **Staging deployment successful** ✅ (v268, 2025-12-26 10:06 CST)
- [ ] Staging validation complete (24 hours stable) ⬅️ Next checkpoint
- [ ] Production deployment successful
- [ ] Production validation complete

### Post-Production Monitoring (First 48 Hours)
- Monitor error rates in logs
- Check response times
- Verify background job processing
- Watch for any deprecation warnings
- Monitor database performance
- Track user-reported issues

---

## Environment Details

- **Local Development**: Ruby 3.1.7p261, Rails 7.0.10, PostgreSQL, macOS arm64
- **Staging**: Heroku-24 stack, Ruby 3.1.7, Rails 7.0.10, PostgreSQL
- **Production**: TBD (will be Heroku-24 after deploy)
- **Repository**: `/Users/devin/repo/dogtag`
- **Current Branch**: `db/ruby3`
- **Main Branch**: `main`

---

## Your Mission

1. **Deploy to staging successfully** - This is your immediate objective
2. **Validate staging thoroughly** - No shortcuts, test everything
3. **Deploy to production successfully** - Only after staging is proven stable
4. **Monitor production** - First 48 hours are critical

**Remember**: Your tenure depends on this. Be methodical, verify everything, and never skip validation steps. When in doubt, check logs, run tests, and ask questions.

---

## Staging Deployment Details (2025-12-26)

**Deployed**: 2025-12-26 10:06 CST
**Release**: v268 (heroku-24 stack)
**Commit**: 26b5369 (Fix Rails 7.0 test failures and compatibility issues)

**Configuration**:
- PostgreSQL: heroku-postgresql (essential-1) via DATABASE_URL
- Redis: heroku-redis (premium-0) via REDIS_URL
- Ruby: 3.1.7p261
- Rails: 7.0.10
- Dynos: web.1 (Unicorn) + worker.1 (Sidekiq) - both UP

**Migrations**: 31 migrations executed successfully

**Status**: App running successfully, monitoring for 24 hours before production deployment

---

**Last verified**: 2025-12-26 12:05 CST
**Next action**: Monitor staging for 24 hours, then deploy to production with `git push heroku db/ruby3:main` (requires explicit confirmation)

---

## Session Notes (2025-12-26)

### Completed Tasks
1. ✅ Configured Playwright to auto-start/stop test server (port 3099)
2. ✅ Fixed parallel execution issues (set workers: 1 for WEBrick compatibility)
3. ✅ Added global setup for database cleanup before test suite
4. ✅ Added Ruby 3.1.7 to CircleCI test matrix
5. ✅ Fixed classy_id type consistency bug for Ruby 3.1 compatibility
6. ✅ Migrated teams.classy_id from string to integer (with data conversion)

### Pending (Not Pushed to Origin)
- Commits `c1a6b04`, `bae96fb`, `7cba95f`, `b4ef458` are local only
- User must push to origin manually (git push restricted to heroku remotes only)
- **Note**: Migration `20251227035004_change_teams_classy_id_to_integer` needs to run on staging/production
