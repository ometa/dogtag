# CLAUDE.md - Dogtag Project Guidelines

This file provides guidance for Claude Code when working on the Dogtag codebase.

## Project Overview

Dogtag is a Ruby on Rails application that manages user and team registration for the annual CHIditarod urban shopping cart race and mobile food drive. It processes payments via Stripe, integrates with Classy for fundraising campaigns, and supports custom per-race survey questions via JSONForm.

## Tech Stack

- **Ruby**: 3.1.7
- **Rails**: 7.0.x
- **Database**: PostgreSQL 17
- **Background Jobs**: Sidekiq with Redis
- **Authentication**: Authlogic 6.x with SCrypt
- **Authorization**: CanCanCan with RoleModel
- **Payments**: Stripe API
- **Testing**: RSpec, FactoryBot, Playwright (integration)
- **CI/CD**: CircleCI

## Development Commands

```bash
# Start PostgreSQL via Docker
docker-compose up -d db

# Run migrations
bundle exec rails db:migrate
RAILS_ENV=test bundle exec rails db:migrate

# Run tests
bundle exec rspec                           # All tests
bundle exec rspec spec/models/              # Model tests only
bundle exec rspec spec/path/to_spec.rb:42   # Single test at line

# Run integration tests (Playwright)
npm test

# Start development server
bundle exec rails server

# Start Sidekiq worker
bundle exec sidekiq -C ./config/sidekiq.yml

# Rails console
bundle exec rails console
```

## Code Style & Conventions

### Ruby/Rails

- Use 2-space indentation
- Keep lines under 120 characters
- Use single quotes for strings unless interpolation needed
- Follow Rails conventions for naming (snake_case for methods/variables, CamelCase for classes)
- Place business logic in models, keep controllers thin
- Use `before_validation` callbacks for data normalization (e.g., email downcasing)

### Testing

- Every feature should have corresponding specs
- Use FactoryBot for test data (factories in `spec/factories/`)
- Use `let` and `let!` for test setup (prefer `let!` when record must exist before test runs)
- Use shared examples for common test patterns
- Mock external services (Stripe, Classy) with WebMock
- Test coverage target: 95%+

### Commit Messages

Follow this format:
```
Short summary of change (imperative mood)

- Bullet points for details if needed
- Explain the "why" not just the "what"

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <model>
```

## Project Structure

```
app/
  models/           # ActiveRecord models with validations and business logic
  controllers/      # Thin controllers, authorization via CanCan
  views/            # HAML templates
  workers/          # Sidekiq background jobs (in workers/ subdirectory)
  validators/       # Custom validators (TeamValidator, PersonValidator, etc.)
  mailers/          # Email templates
  helpers/          # View helpers

lib/
  classy_client.rb  # Classy API wrapper
  classy_user.rb    # Classy user linking logic
  stripe_helper.rb  # Stripe utility methods
  json_form.rb      # JSONForm parsing
  tasks/            # Rake tasks

spec/
  models/           # Model specs
  controllers/      # Controller specs
  workers/          # Background job specs
  lib/              # Library specs
  factories/        # FactoryBot factories
  support/          # Shared examples and test helpers

tests/              # Playwright integration tests (TypeScript)
```

## Key Models & Relationships

- **User** → has_many Teams, has_many CompletedRequirements
- **Team** → belongs_to User, belongs_to Race, has_many People
- **Race** → has_many Teams, has_many Requirements
- **Person** → belongs_to Team
- **Requirement** (STI) → PaymentRequirement, MockPaymentRequirement
- **CompletedRequirement** → joins Team, Requirement, User

### Team Finalization

Teams must meet all requirements to finalize:
1. All people slots filled (configurable per race)
2. All payment requirements satisfied
3. All custom JSONForm questions answered

Use `team.meets_finalization_requirements?` to check status.

## Common Patterns

### Email Handling

All email addresses are automatically downcased before validation. The validation also rejects uppercase emails as a safety net:

```ruby
before_validation :downcase_email
validate :email_must_be_lowercase
```

### Background Jobs

Workers are in `app/workers/workers/` and follow this pattern:

```ruby
class Workers::MyWorker
  include Sidekiq::Worker

  def perform(args)
    # Job logic
  end
end
```

### Event-Driven Architecture

Models use Wisper for pub/sub events:

```ruby
include Wisper.model
# Events broadcast on create/update
```

## Environment Variables

Required for production:
- `DATABASE_URL` - PostgreSQL connection string
- `STRIPE_PUBLISHABLE_KEY` / `STRIPE_SECRET_KEY` - Stripe API keys
- `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_DOMAIN`
- `DEFAULT_FROM_EMAIL`

Optional:
- `CLASSY_CLIENT_ID`, `CLASSY_CLIENT_SECRET`, `CLASSY_ORGS` - Classy integration
- `ROLLBAR_ACCESS_TOKEN` - Error tracking

## Database Operations

```bash
# Restore from dump (via Docker)
docker-compose exec -T db pg_restore --verbose --no-owner --no-acl -U postgres -d dogtag_test < file.dump

# Run specific migration
bundle exec rails db:migrate:up VERSION=20251227035004

# Rollback
bundle exec rails db:rollback

# Normalize emails (rake task)
bundle exec rake db:normalize:emails        # Convert to lowercase
bundle exec rake db:normalize:emails_check  # Dry run
```

## Deployment

Deployed on Heroku with:
- Web dyno: Unicorn (`bundle exec unicorn -p $PORT -c ./config/unicorn.rb`)
- Worker dyno: Sidekiq (`bundle exec sidekiq -C ./config/sidekiq.yml`)

```bash
# Deploy to staging
git push staging main

# Deploy to production
git push heroku main

# Run migrations on Heroku
heroku run rails db:migrate
heroku run rails db:migrate -a staging-app-name
```

## Known Quirks

1. **JSONForm whitelist hack**: New jsonform fields must be added to `HACK_PARAM_WHITELIST` in `app/controllers/questions_controller.rb`

2. **Classy ID type**: `teams.classy_id` is an integer column - ensure proper type casting when working with Classy API responses

3. **Rails 7 SMTP settings**: Uses an initializer (`config/initializers/smtp_settings.rb`) to work around a Rails 7 bug where smtp_settings get reset

4. **Authlogic 6.x**: Password validations are explicit (not automatic) - see User model for the pattern

## Testing External Services

### Stripe
- Use `stripe-ruby-mock` gem in tests
- MockPaymentRequirement available for integration tests without real Stripe calls

### Classy
- Mock HTTP calls with WebMock
- See `spec/lib/classy_client_spec.rb` for patterns

## Quick Reference

| Task | Command |
|------|---------|
| Run all tests | `bundle exec rspec` |
| Run specific test file | `bundle exec rspec spec/models/user_spec.rb` |
| Start PostgreSQL | `docker-compose up -d db` |
| Rails console | `bundle exec rails console` |
| Database migrate | `bundle exec rails db:migrate` |
| Heroku deploy | `git push heroku main` |
| Heroku logs | `heroku logs --tail` |
