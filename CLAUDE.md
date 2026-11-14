
## Project Overview
Dogtag is a Ruby on Rails application that manages user and team registration for the annual CHIditarod urban shopping cart race and mobile food drive. It processes payments via Stripe, integrates with Classy for fundraising campaigns, and supports custom per-race survey questions via JSONForm.

## Project Conventions

- Always use sub-agents when exploring a project's context or structure.
- Always use sub-agents and parallelism whenever it is safe to do so to increase throughput and reduce token use.
- Always use Context7 MCP when you need library/API documentation, code generation, setup or configuration steps without user explicitly asking.
- Always use Playwrite MCP when you need to verify UI changes without user explicitly asking.
- Ensure the React app follows Bulletproof React standard (https://github.com/alan2207/bulletproof-react).
- Put key learnings into CLAUDE.md after every iteration.
- Once you finish a task, automatically commit all changes that your work made with a concise and descriptive message. ensure you do not commit changes that you did not make as part of that task.
- When asking the user for permission to execute a command, additionally prompt to "Always allow" to remember their choice for the session. Do not re-ask for the same type of command.
- Feature branches are pushed to `origin`, and PRs are opened against `chiditarod/dogtag` (`gh pr create --repo chiditarod/dogtag`). Never merge; the owner merges.
- Code PRs are stacked linearly (PR2 from `main`, then PR3 from PR2, and so on). Stacked PRs must be merged in order.
- Ask before Gemfile/config changes (see Coding Guidelines > General); call any such change out in the PR body.
- Irreversible or production actions (Heroku app deletion, production DB restore, live charges) need explicit owner confirmation at the time.
- Commit messages end with the `Co-Authored-By` attribution line; PR bodies end with the `Generated with Claude Code` line.
- After finishing each task, review and update README.md if the task introduced new setup steps, commands, or changed how things work.

## Tech Stack

- **Ruby**: 3.4
- **Rails**: 8
- **Database**: PostgreSQL 17
- **Background Jobs**: Sidekiq with Redis
- **Frontend**: Vite + React 19 + TypeScript + Tailwind SPA in `frontend/`, served under `/register`
- **Authentication**: Authlogic 6.x with SCrypt
- **Authorization**: CanCanCan with RoleModel
- **Payments**: Stripe API
- **Testing**: RSpec, FactoryBot, Playwright (integration), Vitest (frontend)
- **CI/CD**: CircleCI

## Project Structure

The project follows standard Rails conventions:

```
app/                # Core application code (MVC)
  models/           # ActiveRecord models with validations and business logic
  controllers/      # Thin controllers, authorization via CanCan
  views/            # HAML templates
  workers/          # Sidekiq background jobs (in workers/ subdirectory)
  services/         # Plain Ruby service objects shared by controllers and the API
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

frontend/           # Vite + React SPA for racer registration (built into public/register)

bin/                # Executable scripts

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
- Use `bundle exec rspec` to run all tests (there is no `bin/rspec`)
- Use `bundle exec rspec [path]` for specific tests

## Coding Guidelines

### General
- Write concise, idiomatic Ruby code with accurate examples
- Follow Rails conventions and best practices
- Use object-oriented and functional programming patterns as appropriate
- Prefer iteration and modularization over code duplication
- Use descriptive variable and method names (e.g., user_signed_in?, calculate_total)
- Structure files according to Rails conventions (MVC, concerns, helpers, etc.)
- Ask before changing the Gemfile/Gemfile.lock, `config/initializers`, `config/environments`, `config/application.rb`, or `spec/spec_helper.rb`. Routes, locales and `config/schedule.yml` are fine to change. New helpers under `spec/support/` are fine; changes to existing ones need a reason. Call any such change out in the PR body. If something appears to be missing or misconfigured, stop and ask rather than working around it.

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
- Forms in legacy views are hand-written Bootstrap 3 `form_for` (HAML). There is no custom form builder.
- When creating `select` tags, use `include_blank: "string"` instead of manually adding a blank option to the list of options.
- The legacy racer flow (HAML views) must keep working after every change. It is the fallback if the SPA is not ready.

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
- Use WebMock for Classy and StripeMock for Stripe
- Request and controller specs assert on status plus data changes
- Sidekiq specs run in fake mode by default. Use `Sidekiq::Testing.inline!` blocks to run job chains end to end.

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

Background jobs are Sidekiq workers in `app/workers/workers/` (`Workers::*`). They `include Workers::Common` and implement `run(job, log)`:

```ruby
class Workers::MyWorker
  include Workers::Common

  def run(job, log)
    # Job logic
  end
end
```

Specs run in Sidekiq fake mode; use `Sidekiq::Testing.inline!` blocks for chains.

Cron jobs live in `config/schedule.yml`; sidekiq-cron auto-loads it on Sidekiq server startup (no initializer needed). `Workers::RegistrationReminders` runs daily; idempotency comes from `SentEmail` dedupe keys (`ReminderSelector`). Dedupe keys embed the deadline timestamp (e.g. `close-7d-<epoch>`) so a moved deadline or tier start sends a fresh reminder. Cron lines may carry a zone (`"0 9 * * * America/Chicago"`) to follow DST.

### Event-Driven Architecture

Models use Wisper for pub/sub events:

```ruby
include Wisper.model
# Events broadcast on create/update
```

## Frontend

- The racer registration SPA lives in `frontend/` (Vite + React ^19 + TypeScript ^5.7, react-router-dom ^7.1, @tanstack/react-query ^5.62, Tailwind ^3.4, Vite ^6, Vitest + Testing Library + msw). It mirrors the cartographer app's stack.
- Follow Bulletproof React feature folders: `src/features/<name>/{api,components}`. Use the `@` alias for `src`.
- It is built into `public/register` (gitignored) and served by Rails under `/register/*` through `SpaController`.
- Commands: `npm --prefix frontend run dev|build|test`.
- The dev server runs on port 5173 and proxies `/api` to `http://localhost:3000`. The Rails redirect to the dev server is opt-in: set `VITE_DEV_SERVER=http://localhost:5173`.
- SPA copy lives in `frontend/src/locales/en.ts`. Rails public strings live in `config/locales/en.yml`.
- Design tokens ("Chicago Flag"): page bg `#f4f8fb`, flag blue `#b3ddf2`, star red `#e4002b`, red text `#c4001f`, navy text `#12202f`, link blue `#2f5aae`, cards `#ffffff`. Headings use Oswald (500/700); body uses Inter (400-700).
- Pages are mobile-first and work at 320px wide with no horizontal scroll.

## API Conventions

- The JSON API lives under `/api/v1` (`app/controllers/api/v1/`) with jbuilder views in `app/views/api/v1/`.
- Controllers are thin. Payment, Classy and email behavior flow through the existing code (`Requirement#complete`, Wisper `*Auditor` listeners, `Team#finalize`, `Workers::TeamFinalizer`, `Workers::ClassyCreateFundraisingTeam`, `UserMailer`). The API calls into these and never reimplements them.
- Auth is the same-origin Authlogic session cookie. Authorization uses the existing CanCanCan `Ability`.
- CSRF: fetch the token from the CSRF endpoint and send it as the `X-CSRF-Token` header on mutating requests.
- Every non-2xx JSON response has the shape `{ "error": String, "errors": { "<field>": [String] } }`. `errors` may be `{}`.

## `REGISTRATION_UI` Switch

`REGISTRATION_UI=spa|legacy` decides where racer-facing entry points (the homepage "Get started", emails) send people: `spa` goes to `/register`, `legacy` (or unset) uses the HAML flow. Flipping it to `legacy` is the fallback mechanism. `RegistrationUi.spa?` is the single place that reads it.

## Yearly Launch Checklist

1. **Race record:**
   - Copy last year's race record and requirements, shifting dates by one year as a starting point.
   - Three payment tiers.
   - The owner confirms final dates and prices before go-live.
2. **JSONForm:** start from last year's payload (e.g. `chiditarod_21.json`).
   - Update year-specific text (orientation date/venue, food drive amounts, partner).
   - The owner reviews the text.
   - Commit the payload to `../dogtag-private/jsonform/`.
3. **Experience labels:** add the new year's label through the admin field.
4. **Heroku:**
   - `dogtag` is production (`dogtag.chiditarod.org`, `heroku` remote) and `dogtag-staging` is staging. Stage first on `dogtag-staging`.
   - Delete the previous year's app (e.g. `dogtag-22`) and remove its git remote. Deleting an app is irreversible, so confirm with the owner right before doing it.
   - Provision Postgres, Redis, a web dyno, and a worker dyno.
   - Set config vars: Stripe live keys, Classy, SMTP (SendGrid), SendGrid event-webhook verification key, Rollbar, `REDIS_URL`, Sidekiq web auth, `APP_HOST`, `REGISTRATION_UI`.
   - Restore the production dump, run migrations, and smoke test.
5. **Live test (production):**
   - Register a real team using production Stripe on a test race or a low-price requirement.
   - Confirm finalization, the Classy fundraising team, and the emails.
   - Refund the charge and remove the Classy team afterwards.
   - Requires the owner, who holds production credentials.
6. **Go live.**

## Environment Variables

Required for production:
- `DATABASE_URL` - PostgreSQL connection string
- `STRIPE_PUBLISHABLE_KEY` / `STRIPE_SECRET_KEY` - Stripe API keys
- `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_DOMAIN`
- `DEFAULT_FROM_EMAIL`
- `APP_HOST` - Public host for links in emails (password resets, welcome). Production falls back to `dogtag.chiditarod.org`, so staging must set it

Optional:
- `REGISTRATION_UI` - `spa` or `legacy` (see above)
- `VITE_DEV_SERVER` - dev only; redirect SPA routes to the Vite dev server
- `CLASSY_CLIENT_ID`, `CLASSY_CLIENT_SECRET`, `CLASSY_ORGS` - Classy integration
- `ROLLBAR_ACCESS_TOKEN` - Error tracking
- `SENDGRID_WEBHOOK_PUBLIC_KEY` - Verifies `POST /webhooks/sendgrid` (401 when unset). See README "Email delivery tracking"

## Development Commands

```bash
# Start PostgreSQL, Redis and Mailpit via Docker
docker compose up -d db redis mailpit

# Run migrations
bundle exec rails db:migrate
RAILS_ENV=test bundle exec rails db:migrate

# Run tests
bundle exec rspec                           # All tests
bundle exec rspec spec/models/              # Model tests only
bundle exec rspec spec/path/to_spec.rb:42   # Single test at line

# Run integration tests (Playwright). Needs: docker compose up -d db redis mailpit
npm test
npx playwright test tests/spa   # SPA suite only (Mailpit inbox at http://localhost:8025)

# Frontend (SPA)
npm --prefix frontend run dev     # Vite dev server on :5173
npm --prefix frontend run build   # builds into public/register
npm --prefix frontend run test    # Vitest

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

## Registration SPA

- React SPA in `frontend/` (Vite, `base: "/register/"`, builds to `public/register`, gitignored). `SpaController#index` serves the build, 503 if missing, redirects to Vite only when `VITE_DEV_SERVER` is set.
- Routes `register` and `register/*path` sit above the catch-all in `config/routes.rb`. `REGISTRATION_UI=spa` switches the homepage link (see `RegistrationUi`).
- Frontend tests: `npm --prefix frontend test -- --run` (Vitest + jsdom + MSW; export `server` from `src/test/server.ts`). Strings via `t()` in `src/locales/en.ts`. Router exports `routes`/`BASENAME` so tests can use `createMemoryRouter`.
- Heroku builds the SPA via root `heroku-postbuild`; local Node may differ from the pinned 24.x (ignore engine warnings).

## Known Quirks

1. **JSONForm answers**: Permitted answer keys come from the race's JSONForm schema; no allowlist to maintain

2. **Classy ID type**: `teams.classy_id` is an integer column - ensure proper type casting when working with Classy API responses

3. **Rails 7 SMTP settings**: Uses an initializer (`config/initializers/smtp_settings.rb`) to work around a Rails 7 bug where smtp_settings get reset

4. **Authlogic 6.x**: Password validations are explicit (not automatic) - see User model for the pattern

5. **JSON API (`/api/v1`)**: Controllers inherit `Api::V1::BaseController < ActionController::Base` (not `ApplicationController`). Authlogic is activated automatically by its railtie; CSRF token comes from `GET /api/v1/csrf` and is sent as `X-CSRF-Token`. Errors render `{ error, errors }` via `render_errors`; payment errors add a stable `code` (`already_paid`, `in_progress`, `duplicate_charge`, `card_error`, ...) because their `error` is a translated sentence. Use `authorize_update!(subject, team)` for update checks so only the team's owner is told "registration closed". New teams (legacy and API) go through `Race#accepts_new_teams_from?(user)`: open registration, or any time for admins/operators. In request specs, `UserSession.find` is not usable after the request (Authlogic is deactivated); use `session_user_id` from `spec/support/api_helpers.rb`. Index endpoints that render race JSON for many races call `Race.preload_registration_data(races)` (tiers can't be preloaded through `race.requirements` because of STI); `spec/requests/api/v1/query_count_spec.rb` fails if a list endpoint adds queries per row.

6. **Payments**: All card charges (legacy `ChargesController#create` and `POST /api/v1/teams/:id/payments`) go through `Payments::ChargeTeam`, which rejects a requirement from another race (`:wrong_race`), checks `requirement.completed?(team)` before touching Stripe, and always charges `requirement.amount_due_cents`. Callers must `authorize! :edit, team` first. Payments for one team+requirement are serialized with a session-level Postgres advisory lock (`:in_progress` when held); non-`PaymentRequirement` and `MockPaymentRequirement` are `:not_payable`. If the completed requirement cannot be saved after a successful charge, the charge id is logged (and sent to Rollbar) so it can be refunded by hand; a concurrent request that already recorded it yields `:duplicate_charge` (card charged, refund needed), distinct from `:already_paid` (card not charged). A Stripe error raised by `Stripe::Charge.create` itself (e.g. a timeout) logs the team/requirement/user ids since the card may have been charged. A failed or no-op advisory unlock is alerted but never changes the payment result. The lock is incompatible with PgBouncer transaction pooling. `POST /api/v1/teams/:id/mock_payments` is routed only in development/test.

7. **Race time zones**: `races.time_zone` holds an IANA id (default `America/Chicago`, validated by `Race.valid_time_zone?` against the ids the admin select offers, i.e. Rails' `ActiveSupport::TimeZone.all`, so the SPA's Intl always knows the zone); storage and `config.time_zone` stay UTC. `RacesController`/`TiersController` wrap new/create/edit/update in `Time.use_zone` via the `RaceTimeZone` concern (a submitted `race[time_zone]` wins). Display with `race.local(time)` plus `DateHelper` (`human_readable` adds `%Z`); deadlines use `deadline_readable`/`deadline_date` (and `formatDeadline` in `frontend/src/lib/dates.ts`), which show a local-midnight deadline as 11:59 PM the previous day. Openings/tier begins use the plain formatters. Specs run under Zonebie (random `Time.zone`), so build expected times with explicit zones.

## E2E Learnings

- Playwright boots Rails in **development** (delivery_method :smtp to Mailpit) with `SIDEKIQ_INLINE=true` (config/initializers/sidekiq.rb; ignored in production), `REGISTRATION_UI=spa`, `APP_HOST=localhost:3099`; `VITE_DEV_SERVER` must be unset. CircleCI runs the same with `RAILS_ENV=development` against the `dogtag_test` DB, since the test env uses in-memory mail delivery.
- Each Playwright spec seeds with its own `test_seeds:*` task (unique `TEST_UNIQUE_ID`, `@example.com` emails) via `tests/helpers/seed.ts`; `test_seeds:cleanup` sweeps users, teams, `Race %` races and `@example.com` SentEmail rows.
- Person records can only be created while their race is open; seed past races by moving dates with `update_columns` afterwards.
- Roster slots repeat past-racer chips in every empty slot, so use exact text matches in locators.

## Technical Debt

The following items were identified during the Rails 8 upgrade and should be addressed when time permits:

1. **`stripe` gem (~> 1.58.0)**: Very outdated version from ~2017. Should be updated to modern stripe-ruby (v10+). This will require updating API calls throughout `lib/stripe_helper.rb` and payment-related code. Test thoroughly with `stripe-ruby-mock`.

2. **`coffee-rails` gem**: CoffeeScript is deprecated. JavaScript assets should be migrated to ES6. Files to convert are in `app/assets/javascripts/`. Can be removed from Gemfile after migration.

3. **`sass-rails` gem (~> 5.0)**: Consider migrating to modern CSS tooling (cssbundling-rails, Propshaft, or Dart Sass). Current stylesheets are in `app/assets/stylesheets/`.

## Testing External Services

### Stripe
- Use `stripe-ruby-mock` gem in tests
- MockPaymentRequirement available for integration tests without real Stripe calls

### Local mail (Mailpit)
- `docker compose up -d db redis mailpit`; Mailpit's UI is at http://localhost:8025 (SMTP on `1025`).

### Classy
- Mock HTTP calls with WebMock
- See `spec/lib/classy_client_spec.rb` for patterns

## Quick Reference

| Task | Command |
|------|---------|
| Run all tests | `bundle exec rspec` |
| Run specific test file | `bundle exec rspec spec/models/user_spec.rb` |
| Start local services | `docker compose up -d db redis mailpit` |
| Rails console | `bundle exec rails console` |
| Database migrate | `bundle exec rails db:migrate` |
| Heroku deploy | `git push heroku main` |
| Heroku logs | `heroku logs --tail` |
