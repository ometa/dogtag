# Project Guidelines

## Project Overview
Dogtag is a Ruby on Rails application that manages user and team registration for the annual CHIditarod urban shopping cart race and mobile food drive. It processes payments via Stripe, integrates with Classy for fundraising campaigns, and supports custom per-race survey questions via JSONForm.

## Tech Stack

- **Ruby**: 3.4
- **Rails**: 8
- **Database**: PostgreSQL 17
- **Background Jobs**: Sidekiq with Redis
- **Authentication**: Authlogic 6.x with SCrypt
- **Authorization**: CanCanCan with RoleModel
- **Payments**: Stripe API
- **Testing**: RSpec, FactoryBot, Playwright (integration)
- **CI/CD**: CircleCI

## Project Structure

The project follows standard Rails conventions:

```
app/                # Core application code (MVC)
  models/           # ActiveRecord models with validations and business logic
  controllers/      # Thin controllers, authorization via CanCan
  views/            # HAML templates
  workers/          # Sidekiq background jobs (in workers/ subdirectory)
  validators/       # Custom validators (TeamValidator, PersonValidator, etc.)
  mailers/          # Email templates
  helpers/          # View helpers

lib/                # Library code
  classy_client.rb  # Classy API wrapper
  classy_user.rb    # Classy user linking logic
  stripe_helper.rb  # Stripe utility methods
  json_form.rb      # JSONForm parsing
  tasks/            # Rake tasks

spec/               # Unit tests
  models/           # Model specs
  controllers/      # Controller specs
  workers/          # Background job specs
  lib/              # Library specs
  factories/        # FactoryBot factories
  support/          # Shared examples and test helpers

tests/              # Playwright integration tests (TypeScript)

bin/                # Eecutable scripts

config/             # Configuration files

db/                 # Database schema and migrations

public/             # Public assets
```

## Development Workflow

### Running the Application
- Use `bin/rails server` to start the development server
- Use `bin/rails console` to start the Rails console

### Database Operations
- Use `bin/rails db:migrate` to run pending migrations
- Use `bin/rails db:seed` to seed the database
- Use `bin/rails db:reset` to reset the database

### Running Tests
- Use `bin/rspec` to run all tests
- Use `bin/rspec [path]` for specific tests

## Coding Guidelines

### General
- Write concise, idiomatic Ruby code with accurate examples
- Follow Rails conventions and best practices
- Use object-oriented and functional programming patterns as appropriate
- Prefer iteration and modularization over code duplication
- Use descriptive variable and method names (e.g., user_signed_in?, calculate_total)
- Structure files according to Rails conventions (MVC, concerns, helpers, etc.)
- NEVER modify the Gemfile, Rails configuration or initializers, nor RSpec configuration or test support files. All instructions are intended to be implemented within the existing application configuration and dependencies. If something appears to be missing or misconfigured, stop.

### Common Patterns
- If a form url or controller redirect is to an action in the same controller, use a hash with the action name as the key e.g. `{ action: :new }`
- When making migrations, use `text` for all string fields; never use `string` or `varchar`

### Naming Conventions
- Use snake_case for file names, method names, and variables
- Use CamelCase for class and module names
- Follow Rails naming conventions for models, controllers, and views

### Ruby and Rails Usage
- Use Ruby 3.x features when appropriate (e.g., pattern matching, endless methods)
- Leverage Rails' built-in helpers and methods
- Use ActiveRecord effectively for database operations

### Syntax and Formatting
- Follow the Ruby Style Guide (https://rubystyle.guide/)
- Use Ruby's expressive syntax (e.g., unless, ||=, &.)
- Prefer double quotes for strings
- Always strip whitespace at the end of lines and ensure a blank line exists at the end of the file

### Controllers
- When adding new controllers or actions, don't forget to update the routes.rb
- Use `expect` syntax instead of `require`/`allow` for strong parameters:
  ```ruby
  # Good
  params.expect(user: [:name, :favorite_pie])

  # Bad
  params.require(:user).permit(:name, :favorite_pie)
  ```
- Unless parameters are reused more than once, assign strong parameters to a local variable rather than a method
- When linking or redirecting to an action in the same controller, use `url_for(action: "the_action")` instead of path helpers

### View templates
- Use the custom form builder `FrontdoorForm` which contains helpers for structure bootstrap forms.
- When using `FrontdoorForm`, do not add Bootstrap classes like `form-label`/`form-control`/`form-select`; they're already added by the FrontdoorForm builder.
- Most simple form inputs will have this structure of `group`, `label`, `input`, and `errors`:
  ```
  <%= f.group(:first_name, class: "col-3") do %>
    <%= f.label :first_name, "First Name" %>
    <%= f.input :first_name %>
    <%= f.errors :first_name %>
  <% end %>
  ```
- When creating `select` tags, use `include_blank: "string"` instead of manually adding a blank option to the list of options.

### Internationalization
- All public or client-facing pages will be translated. Admin pages will not be translated.
- Follow Rails I18n conventions for extracting strings to config/locales.
- Use relative identifiers whenever possible. For example, the relative `t(".title")` in `app/views/pages/homepage` is preferred to `t("pages.homepage.title")`.
- For simple strings that contain HTML, name the key with `_md` suffix and author the strings in Markdown instead of HTML.
  - The Markdown will be automatically rendered to HTML and marked as HTML safe.
  - Multiline strings should break paragraphs with 2 newlines. Single-line strings will not be wrapped with p tags.
  - Do not use the `_md` suffix when strings do not contain HTML formatting.
  - This custom functionality is implemented in `config/initializers/markdown.rb`.

### Database Migrations
- Always create a migration using `bin/rails g migration <NAME>`. If a migration has been created in the current development feature branch, rollback the migration, edit it and then roll forward rather than creating a new migration.
- Use `text` for all string fields; never use `string` or `varchar`
- Use `datetime` instead of `timestamp`
- Assume that Boolean values should be nullable unless specified

### Testing
- Write tests using RSpec. It's ok to put multiple assertions in the same example
- Use factories (FactoryBot) for test data generation
- Prefer real objects over mocks unless there is an external dependency like a third party API call. Use `instance_double` if necessary; never `double`
- Don't test declarative configuration. For validations, only test that it's not valid when the validation is violated. `shoulda-matchers` is not used.
- Test controllers behaviorally: assert on status code and/or data changes
- Use Timecop for time traveling
- By default tests use GoodJob Inline Adapter. To use the Active Job test adapter use the `:active_job` option for the test

#### System Tests
- When writing System Tests, use `css_id(*)` and `css_class(*)` instead of `"#{dom_id(*)}"` `"#{dom_class(*)}"`
- Use Capybara async matchers and expectations and generally avoid asserting on `find` methods that may be flaky.

## Performance Optimization
- Use database indexing effectively
- Implement caching strategies (fragment caching, Russian Doll caching)
- Use eager loading to avoid N+1 queries
- Optimize database queries using includes, joins, or select

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

# Download a production database and then restore it locally
# Useful for testing migrations:
heroku pg:backups:capture --app dogtag
curl -o file.dump `heroku pg:backups:url --app dogtag`
pg_restore --verbose --clean --no-acl --no-owner -h localhost -d dogtag_development file.dump
```

## Known Quirks

1. **JSONForm whitelist hack**: New jsonform fields must be added to `HACK_PARAM_WHITELIST` in `app/controllers/questions_controller.rb`

2. **Classy ID type**: `teams.classy_id` is an integer column - ensure proper type casting when working with Classy API responses

3. **Rails 7 SMTP settings**: Uses an initializer (`config/initializers/smtp_settings.rb`) to work around a Rails 7 bug where smtp_settings get reset

4. **Authlogic 6.x**: Password validations are explicit (not automatic) - see User model for the pattern

## Technical Debt

The following items were identified during the Rails 8 upgrade and should be addressed when time permits:

1. **`stripe` gem (~> 1.58.0)**: Very outdated version from ~2017. Should be updated to modern stripe-ruby (v10+). This will require updating API calls throughout `lib/stripe_helper.rb` and payment-related code. Test thoroughly with `stripe-ruby-mock`.

2. **`coffee-rails` gem**: CoffeeScript is deprecated. JavaScript assets should be migrated to ES6. Files to convert are in `app/assets/javascripts/`. Can be removed from Gemfile after migration.

3. **`sass-rails` gem (~> 5.0)**: Consider migrating to modern CSS tooling (cssbundling-rails, Propshaft, or Dart Sass). Current stylesheets are in `app/assets/stylesheets/`.

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
