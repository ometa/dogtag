
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
- Prefer `bin/check` (all suites, quiet: one summary line per step, failure details only, full logs in `tmp/check/`); `bin/check rspec|frontend|build|e2e` runs one step

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
- For strings that contain HTML, name the key with an `_html` suffix and author it as HTML (Rails marks it safe). There is no Markdown initializer or `_md` key support; only `ConfirmationText` renders Markdown (see Registration SPA).

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
- Every frontend (SPA) feature needs a Playwright e2e spec in `tests/spa/` as well as Vitest tests. Seed it with its own `test_seeds:*` task (unique `TEST_UNIQUE_ID`, `@example.com` emails) and add that data to `test_seeds:cleanup`. State in the PR whether the e2e spec was actually run.

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

CSV exports (`Team.export`) write the team name with `Team#library_name` ("The Secret Gentlemen" becomes "Secret Gentlemen, The"); only a leading "The" is moved and the stored name is unchanged. The export dropdown on the race page has an info icon saying so.
`Team.export` also prefixes a team name starting with `=`, `+`, `-` or `@` with `'` so spreadsheets do not evaluate it (name column only). Info icons in the legacy admin views use `.js-tooltip` (`app/assets/javascripts/tooltips.js`); bootstrap.min.js loads after application.js, so init runs on DOM ready, and the click handler stops propagation so a tap does not close an open dropdown.

Deleting a team: `Team#deletable?` (not finalized, nothing paid) gates `DELETE /api/v1/teams/:id` and the legacy `teams#destroy`. The Ability lets a captain delete their own deletable team while registration is open, and operators any deletable team; admins can delete any team without payments. People are `dependent: :destroy`. The SPA shows `DeleteTeam` from `team.deletable`, and staff delete from the Pending table on the race registrations page.

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
- Header logo: `frontend/public/logo.png` (640x389, small ribbon lettering) is sized `h-16` / `min-[400px]:h-20` / `sm:h-24` in `RegisterLayout`; at 320px the logged-in nav leaves room for about `h-16`, so do not go taller without wrapping the nav. Stripe Checkout wants a roughly square image, so it uses `logo-square.png` (256x256, logo centered on opaque white); regenerate it with `sips --resampleWidth 256` then `sips -p 256 256 --padColor FFFFFF` if the logo changes.
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

The 2026 production runbook with exact commands is `docs/runbooks/2026-production-launch.md`; copy it for the next year.

1. **Race record:**
   - Copy last year's race record and requirements, shifting dates by one year as a starting point.
   - Three payment tiers.
   - The owner confirms final dates and prices before go-live.
2. **JSONForm:** start from last year's payload (e.g. `chiditarod_21.json`).
   - Update year-specific text (orientation date/venue, food drive amounts, partner).
   - The owner reviews the text.
   - Commit the payload to `../dogtag-private/jsonform/`.
3. **Experience labels:** add the new year's label through the admin field.
   - **Confirmation text:** fill in the race's confirmation text (Markdown) in the admin race form and have the owner review it; it appears in the completion modal, the team page header and the finalized email.
4. **Heroku:**
   - `dogtag` is production (`dogtag.chiditarod.org`, `heroku` remote) and `dogtag-staging` is staging. Stage first on `dogtag-staging`.
   - Delete the previous year's app (e.g. `dogtag-22`) and remove its git remote. Deleting an app is irreversible, so confirm with the owner right before doing it.
   - Provision Postgres, Redis, a web dyno, and a worker dyno.
   - Set config vars: Stripe live keys, Classy, SMTP (MXRoute), Rollbar, `REDIS_URL`, Sidekiq web auth, `APP_HOST`, `REGISTRATION_UI`, `MALLOC_ARENA_MAX=2`, `NPM_CONFIG_OMIT=dev` (keeps root test devDependencies out of the build).
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
- `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_DOMAIN` - all mail goes through MXRoute SMTP. MXRoute has no event webhooks, so email "delivery verification" (`rake emails:verify`) means "logged as sent" in `sent_emails`
- `DEFAULT_FROM_EMAIL`
- `APP_HOST` - Public host for links in emails (password resets, welcome). Production falls back to `dogtag.chiditarod.org`, so staging must set it

Optional:
- `REGISTRATION_UI` - `spa` or `legacy` (see above)
- `FEEDBACK_EMAIL` - where the SPA's "Report a problem" link (`POST /api/v1/feedback`, `UserMailer#feedback_email`) sends mail; defaults to `registration@chiditarod.org`. Logged-in racers only (the SPA hides the link and the API answers 401 otherwise); capped at 5 sends per account per hour
- `VITE_DEV_SERVER` - dev only; redirect SPA routes to the Vite dev server
- `CLASSY_CLIENT_ID`, `CLASSY_CLIENT_SECRET`, `CLASSY_ORGS` - Classy integration
- `ROLLBAR_ACCESS_TOKEN` - Error tracking

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
heroku restart -a staging-app-name   # after any migration that adds a column the code reads

# Download a production database and then restore it locally
# Useful for testing migrations:
heroku pg:backups:capture --app dogtag
curl -o file.dump `heroku pg:backups:url --app dogtag`
pg_restore --verbose --clean --no-acl --no-owner -h localhost -d dogtag_development file.dump
```

The `Procfile` has no `release:` phase, so a push does not migrate. When a deploy adds a column that views or JSON read (e.g. `people.instagram`, read by every person row), pages that read it fail from the push until the migration has run. Dynos that booted before the migration keep the old column list, so `heroku restart` after migrating. Run the migration right after the push, on `dogtag-staging` first. A migration that drops a column (e.g. `people.twitter`) also loses its data on rollback, so run `heroku pg:backups:capture --app dogtag` first; until `heroku restart`, dynos that booted earlier still list the dropped column in every INSERT/UPDATE and fail with "column does not exist".

## Registration SPA

- React SPA in `frontend/` (Vite, `base: "/register/"`, builds to `public/register`, gitignored). `SpaController#index` serves the build, 503 if missing, redirects to Vite only when `VITE_DEV_SERVER` is set.
- Routes `register` and `register/*path` sit above the catch-all in `config/routes.rb`. `REGISTRATION_UI=spa` switches the homepage link (see `RegistrationUi`).
- Frontend tests: `npm --prefix frontend test -- --run` (Vitest + jsdom + MSW; export `server` from `src/test/server.ts`). Strings via `t()` in `src/locales/en.ts`. Router exports `routes`/`BASENAME` so tests can use `createMemoryRouter`.
- Heroku builds the SPA via root `heroku-postbuild`; local Node may differ from the pinned 24.x (ignore engine warnings).
- Guided tour on the team page (`frontend/src/features/tour/`: `storage.ts`, `stops.ts`, `components/guided-tour.tsx`; copy under `tour.*` in `en.ts`). Targets carry `data-tour` (`flag` on the progress flag; `racers`, `questions`, `fee`, `in` on each step's heading row (`tour.flag` copy: "Four stars to the start line")), and a stop whose target is missing is skipped. `teamTourStops` leaves out `questions` when the race has none and `fee` when no fee is due. `TeamChecklist` opens it once per mount only when the race is open, the team is not finalized, and `shouldAutoStart(me.id)` is true (not seen, not switched off with `dogtag:tour:off`, and localStorage writable). Ending it (`End tour`, `Done`, Escape) writes `dogtag:tour:team:v1:<user id>` (and an in-memory mark, so blocked storage cannot bring it back); `Take the tour` in `TeamHeader` replays it. Below `lg` the card docks to the bottom or top edge and the page scrolls per `dockPopup` (`placement.ts`); from `lg` it sits next to the target (`placePopup`).
- Crew picker (`frontend/src/features/roster/components/crew-picker.tsx`, `crew-pick-list.tsx`, `crew-review.tsx`): the Racers step has one `Pick from past teams (N)` button instead of per-slot chips. Step 1 ticks past racers (capped at the open spots), step 2 reviews one person at a time. Each of the seven details (name, email, phone, ZIP, years racing, Instagram, TikTok) must be ticked or changed before `Add {first name} to the team` enables, and a person is saved only when that button is pressed. `Add yourself` reviews the captain alone when they are one of their own past racers; otherwise it opens the `Add a racer` form pre-filled from the account. Escape backs out one level at a time: it clears a non-empty search, then puts back a line opened with `Change`, and only then closes the dialog (`useFocusTrap`, used by `DialogSheet`, ignores an Escape whose `defaultPrevented` is set). Close and Escape do nothing while a save is in flight. A racer added through the picker stays out of the list for the visit even if their email was changed in review (`pickedFrom` in `roster-card.tsx`).
- Wrapping inside a grid: `break-words` does not shrink a grid track's min-content width, so one long email widens the whole column. Use `grid-cols-[minmax(0,1fr)]` on the grid with `[overflow-wrap:anywhere]` on the values that must wrap.
- Team page progress is `FlagProgress` (four labeled Chicago-flag stars: Team, Racers, Questions, Fee) driven by `stepStates(team)` in `features/teams/utils.ts`: Team is lit once the team exists, Racers when the roster is full, Questions when answered (or not required), Fee when paid (not while it only opens later); a finalized team has all four lit. `cardSteps` gives the card statuses. The team route is the only wide one: `handle: { wide: true }` in `app/router.tsx`, read by `RegisterLayout`.
- Completion confirmation: `races.confirmation_text` is Markdown rendered by `ConfirmationText.to_html` (`app/services/confirmation_text.rb`: commonmarker, then `sanitize` with a small tag allowlist). `races.confirmation_text` is capped at `Race::CONFIRMATION_TEXT_MAX_LENGTH` (5000). `TeamChecklist` exposes `confirmation_html` (nil until the team is finalized, so it is neither rendered nor sent early) and `show_confirmation` (finalized, viewer is the owner, `teams.confirmation_seen_at` blank). The SPA shows `CompletionDialog` once, and closing it calls the owner-only `POST /api/v1/teams/:team_id/confirmation` (`useMarkConfirmationSeen`), which sets `confirmation_seen_at`; staff viewing never clear it and re-finalizing does not reset it. The migration backfilled `confirmation_seen_at` for already finalized teams and seeded `confirmation_text` only for races upcoming at migration time (later races start blank). `ConfirmationText` limits link `href` to http, https and mailto. The same text feeds the team page header (`ConfirmationText`) and `team_finalized_email` (team number, `Team#classy_fundraising_url` line, help line `dogtag@chiditarod.org`). The racers card collapses on finalize with a `Hide racers` toggle.
- Racers give `instagram` and `tiktok` handles (model, API, SPA, legacy form; both optional, normalized to a lowercase `@handle`). The unused `people.twitter` column was dropped; `teams.twitter` still exists.
- New team flag (#301): `teams.new_team` is true when the sum of `people.experience` is 0 (blank counts as 0), nil with no racers. `Person` after_save (when experience or team changes) and after_destroy call `Team#refresh_new_team`, a conditional `update_all` that skips teams with `new_team_overridden`; reload a team to see the new value. Staff set it through the virtual `new_team_setting` (`auto`/`yes`/`no`), which `TeamsController#team_params` permits only for admins and operators. Display text lives in `NewTeamHelper` (admin-only, untranslated). `teams.experience` is a separate self-reported team label index and does not feed the flag. Nothing reads the old `raced-in-past` JSONForm answer; it remains only in fixtures and the staging seed until #304.
- Team picker (#302): racers say which other teams they want to race with. `team_buddies` is a directional join table (`team_id` names `buddy_team_id`; same race, no self-pick, unique pair, FK cascade) and `teams.other_buddies` is free text (stripped, blank becomes nil, max `Team::OTHER_BUDDIES_MAX_LENGTH` 1000). `GET /api/v1/teams/:team_id/buddy_options` returns `{ teams: [{ id, name, finalized }] }` for the other teams in the race (name only, sorted by `LOWER(name)` then id, authorized with `:edit`). `GET/PUT /api/v1/teams/:team_id/questions` also read and write `buddy_team_ids` and `other_buddies`: an absent key leaves the value unchanged, a present key replaces it, and bad ids are a 422 `invalid_buddies`. A PUT without `answers` still clears the answers, so the SPA always sends them. Picks cannot be saved for a race without a JSONForm because `no_questions` runs first. The SPA `BuddyPicker` is the first field of the Questions card (search, "Fully registered"/"Still registering" tags, "Other..." reveals the free text); it is optional and has no effect on finalization. The admin CSV export ends with a `racing_with` column (picked names, then the other text, `spreadsheet_safe` per element) and the admin team page shows "Racing with" to admins and operators. The old `buddies` JSONForm question stays only in old answers and the in-repo JSONForm fixtures; it was removed from `../dogtag-private/jsonform/chiditarod_22.json` (private repo commit `5e061f2`), so a 2027 race loaded from that payload shows the picker only. Deploy order: the migration adds `teams.other_buddies` and the `team_buddies` table, and every Team save or page that touches them (team create/update, finalize, the admin page, the CSV export, delete, the Questions card) fails until the migration has run and dynos have restarted, so push, migrate immediately (`heroku run rails db:migrate -a dogtag-staging` first), then `heroku restart`; do production in low traffic. Tests: `test_seeds:buddy_picker` and `tests/spa/buddy-picker.spec.ts`; on a machine with another session running, use `TEST_PORT=3199` and a separate `DATABASE_URL` (e.g. `dogtag_test_2`) so runs do not collide.
- Nokogiri's HTML parser does not add an implied `<tbody>`, so in `render_views` specs select legacy table rows with `#table_id tr` and filter for `> td`.

## Known Quirks

1. **JSONForm answers**: Permitted answer keys come from the race's JSONForm schema; no allowlist to maintain

2. **Classy ID type**: `teams.classy_id` is an integer column - ensure proper type casting when working with Classy API responses

3. **Rails 7 SMTP settings**: Uses an initializer (`config/initializers/smtp_settings.rb`) to work around a Rails 7 bug where smtp_settings get reset

4. **Authlogic 6.x**: Password validations are explicit (not automatic) - see User model for the pattern

5. **JSON API (`/api/v1`)**: Controllers inherit `Api::V1::BaseController < ActionController::Base` (not `ApplicationController`). Authlogic is activated automatically by its railtie; CSRF token comes from `GET /api/v1/csrf` and is sent as `X-CSRF-Token`. Errors render `{ error, errors }` via `render_errors`; payment errors add a stable `code` (`already_paid`, `in_progress`, `duplicate_charge`, `card_error`, ...) because their `error` is a translated sentence. Use `authorize_update!(subject, team)` for update checks so only the team's owner is told "registration closed". New teams (legacy and API) go through `Race#accepts_new_teams_from?(user)`: open registration, or any time for admins/operators. In request specs, `UserSession.find` is not usable after the request (Authlogic is deactivated); use `session_user_id` from `spec/support/api_helpers.rb`. Index endpoints that render race JSON for many races call `Race.preload_registration_data(races)` (tiers can't be preloaded through `race.requirements` because of STI); `spec/requests/api/v1/query_count_spec.rb` fails if a list endpoint adds queries per row.

6. **Payments**: All card charges (legacy `ChargesController#create` and `POST /api/v1/teams/:id/payments`) go through `Payments::ChargeTeam`, which rejects a requirement from another race (`:wrong_race`), checks `requirement.completed?(team)` before touching Stripe, returns `:roster_incomplete` (422) while `team.needs_people?` unless the payer is staff (payment specs build teams with `:with_enough_people`; the SPA fee card keeps the price, next tier and paid rows and hides only the Pay button behind `fee.rosterFirst`, and the legacy view shows `no_pay_roster` instead of the Stripe embed unless an admin or operator is viewing; the SPA has no staff flag, so staff take payment for an incomplete team in the legacy view), and always charges `requirement.amount_due_cents`. Callers must `authorize! :edit, team` first. Payments for one team+requirement are serialized with a session-level Postgres advisory lock (`:in_progress` when held); non-`PaymentRequirement` and `MockPaymentRequirement` are `:not_payable`. If the completed requirement cannot be saved after a successful charge, the charge id is logged (and sent to Rollbar) so it can be refunded by hand; a concurrent request that already recorded it yields `:duplicate_charge` (card charged, refund needed), distinct from `:already_paid` (card not charged). A Stripe error raised by `Stripe::Charge.create` itself (e.g. a timeout) logs the team/requirement/user ids since the card may have been charged. A failed or no-op advisory unlock is alerted but never changes the payment result. The lock is incompatible with PgBouncer transaction pooling. `POST /api/v1/teams/:id/mock_payments` is routed only in development/test.

7. **Race time zones**: `races.time_zone` holds an IANA id (default `America/Chicago`, validated by `Race.valid_time_zone?` against the ids the admin select offers, i.e. Rails' `ActiveSupport::TimeZone.all`, so the SPA's Intl always knows the zone); storage and `config.time_zone` stay UTC. `RacesController`/`TiersController` wrap new/create/edit/update in `Time.use_zone` via the `RaceTimeZone` concern (a submitted `race[time_zone]` wins). Display with `race.local(time)` plus `DateHelper` (`human_readable` adds `%Z`); deadlines use `deadline_readable`/`deadline_date` (and `formatDeadline` in `frontend/src/lib/dates.ts`), which show a local-midnight deadline as 11:59 PM the previous day. Openings/tier begins use the plain formatters. Specs run under Zonebie (random `Time.zone`), so build expected times with explicit zones.

8. **Worker memory / Classy HTTP**: `ClassyClient` reuses one memoized `HTTPClient` (`http_client`); never build an `HTTPClient` per request. Each one allocates an OpenSSL context in native memory, and `Workers::ClassyCacheOrgMemberCacher` (every 20 min, ~318 pages) ratcheted the Basic worker's RSS into R14/R15 kills. Ruby `GC.stat[:heap_live_slots]` stayed flat, so check native churn, not just retained objects. Both Heroku apps also need `MALLOC_ARENA_MAX=2`: the worker boots with `RAILS_ENV=production`, so `config/sidekiq.yml` gives it 5 threads, and each thread's glibc arena kept ~70 MB (5 x 70 MB + ~190 MB boot > 512 MB). With both fixes the staging worker levels off at ~340 MB. Staging has `log-runtime-metrics` on (`sample#memory_total` in `heroku logs -d worker`).

9. **Feedback (`POST /api/v1/feedback`)**: requires a logged-in user (`require_api_user!`; the SPA's `FeedbackLink` renders only when `useMe` has a user). The cap (`SEND_LIMIT` 5 per `SEND_WINDOW` 1 hour per account) counts the user's non-failed `kind: "feedback"` rows in `sent_emails`, so it holds across dynos without a cache store and failed deliveries do not count; two simultaneous requests can both pass the check, so it can overshoot by a send. The client's `context.team_id` is only a claim. The controller attaches the team (email body, `sent_emails` tracking) only when `Ability.new(current_user).can?(:show, team)` (CanCan checks the exact action asked, so `:read` does not match rules written for `:show`); otherwise the email says `claimed team id N (unverified)`. A non-hash `context` is ignored. The email puts sender, team and page above a labelled message so a sender cannot forge a footer. `UserMailer::STAFF_EMAIL` is the staff address (also the footer's `global_questions`); `FEEDBACK_EMAIL` overrides it when non-empty.

## E2E Learnings

- CircleCI Smarter Testing: the `test` job runs `circleci testsuite run "rspec"` (suite in `.circleci/test-suites.yml`, results uploaded by `store-test-results: true`, so there is no `store_test_results` step). Validate locally with `circleci testsuite doctor rspec` (needs `brew install circleci` and `circleci extension install testsuite`). Doctor's subprocess loses the rbenv shims and hits `/usr/bin/bundle` (system Ruby 2.6): temporarily put `~/.rbenv/shims/bundle` in the `run:` line to validate, and never commit that. No credit-charged features (impact analysis, dynamic splitting, auto-rerun) are enabled.

- Staging runs on synthetic data, not a production dump: `bin/rails staging:seed` (`lib/staging_seed.rb`) fills an **empty** database. It needs `SEED_ADMIN_EMAIL`, `SEED_ADMIN_PASSWORD` and `SEED_PASSWORD`, plus optional `SEED_EMAIL_BASE` (plus-addresses every seeded email into the test mailbox) and `SEED_CLASSY_CAMPAIGN_ID`. It refuses on the production host, with a live Stripe key, or with existing users/races. It covers past racers, a finalized team, a half-paid team, a just-started team, a full race with a waitlist, a not-yet-open race and a closed race. Seeded payments use fake `ch_seed_*` ids, so refunds of them fail.

- Playwright boots Rails in **development** (delivery_method :smtp to Mailpit) with `SIDEKIQ_INLINE=true` (config/initializers/sidekiq.rb; ignored in production), `REGISTRATION_UI=spa`, `APP_HOST=localhost:3099`; `VITE_DEV_SERVER` must be unset. CircleCI runs the same with `RAILS_ENV=development` against the `dogtag_test` DB, since the test env uses in-memory mail delivery.
- Each Playwright spec seeds with its own `test_seeds:*` task (unique `TEST_UNIQUE_ID`, `@example.com` emails) via `tests/helpers/seed.ts`; `test_seeds:cleanup` sweeps users, teams, `Race %` races and `@example.com` SentEmail rows.
- E2E targets (`tests/e2e/`, `E2E_TARGET`): `npm run e2e` = local, mock payments, Mailpit; `npm run e2e:stripe` = local, Stripe test card; `npm run e2e:staging` = `dogtag-staging.herokuapp.com`, Stripe test card, optional IMAP check (`E2E_CHECK_EMAIL=1`). The Classy check runs on either target only with `E2E_CHECK_CLASSY=1` (credentials alone never enable it): it gives the race a campaign, so the server creates real Classy members and teams. Locally the server reads `CLASSY_*` from `.env`; the config passes the `.env.e2e` Classy keys through only when the check is on. Settings live in the gitignored `.env.e2e`; see `tests/README.md`.
- The host guard (`tests/e2e/target.ts`) allows only `localhost`, `127.0.0.1` and `dogtag-staging.herokuapp.com`, and refuses `dogtag.chiditarod.org`, `dogtag.herokuapp.com` and `*.chiditarod.org` first; no env var extends the lists, and a `BASE_URL` host must belong to the chosen target. Nothing under `tests/` may use the `heroku` CLI, the Heroku API or `heroku run`. Never pay unless the race's publishable key starts with `pk_test_`.
- The staging run logs in as an **operator**, never an admin, and builds its own `Race E2E <runId> <yyyy-mm-ddThh:mm>Z` through the admin UI. Races are retired (dates moved to the past, ` [retired]` appended), not deleted; `retireRace` refuses names without the `Race E2E ` prefix. A run sweeps its own leftovers and other runs' open E2E races older than two hours, so concurrent runs don't retire each other's races. Classy teams are deleted only if named `Test Team E2E *` on the allowlisted campaign.
- Classy refuses `DELETE /fundraising-teams/:id` (400, `Can not delete a Fundraising Team that has active Fundraising Pages.`) while the team has a page; the server creates the captain's page with the team. `deleteFundraisingTeam` (`tests/e2e/classy.ts`) deletes the team's pages first, then the team, and its error messages include Classy's response body. Whether a delete is hard or only archives is unverified. A run that dies before cleanup leaves a `Test Team E2E *` team on campaign 867400; remove it by hand.
- On staging, racers are IMAP plus-addresses (`<user>+<runId>@<domain>` from `E2E_EMAIL_BASE`); only mail to this run's address is deleted from the shared mailbox. Locally, mail goes through Mailpit.
- Staging secrets and `.env.e2e` never go into CI or artifacts. CI runs `npm test` with `E2E_CHECK_EMAIL=1` against Mailpit only. Playwright titles every `fill` step `Fill "<value>"` and the HTML report keeps step titles for passed tests, so passwords, the operator login and private mailbox addresses go in through `fillSecret` (`tests/e2e/fill-secret.ts`, native value setter + `input`/`change`, titled "Evaluate"). admin-auth records no trace, video or screenshot; on staging race-setup and race-teardown keep no trace or video (they carry the operator's session cookie), and neither does registration (traces keep evaluate arguments, request bodies and DOM snapshots, so the mailbox address and racer password); failure screenshots stay; `race-teardown` deletes `playwright/.auth/staff.json`. `payFee` takes the race's publishable key and refuses a non-`pk_test_` key itself. Registration folds the retry number into its run id (`<runId>-r1`) so a CI retry can sign up again.
- Before `e2e:staging`, check that staging has run the latest migrations (`heroku run -a dogtag-staging "bin/rails db:migrate:status"`) and was restarted afterwards. A pending migration shows up as a generic "Something went wrong" in the SPA and a 500 `UnknownAttributeError` in `heroku logs` (the `people.instagram` column broke "Add 5 racers" this way). The Stripe Checkout popup's expiry field sometimes drops its last keystroke (`12 / 3`), so `payWithStripeCheckout` retypes until the field reads `12 / 34`.
- App changes the suite relies on: operators can open the new-requirement form (`can :new, Requirement`); `Requirement.allowed_types` limits the type select ("Mock payment" is offered outside production only); the legacy login fields have sr-only labels.
- Person records can only be created while their race is open; seed past races by moving dates with `update_columns` afterwards.
- `playwright.config.ts` sets `storageState` so `dogtag:tour:off` is `1` in localStorage for every test; otherwise the tour opens by itself and blocks clicks on the team page. A spec that wants the tour clears it with `test.use({ storageState: { cookies: [], origins: [] } })` (`tests/spa/guided-tour.spec.ts`). Any other checkout's Playwright config needs the same `storageState` lines, or its specs will be blocked by the tour. The `origin` must match the `baseURL` origin.
- The picker dialog is portaled to `document.body`, so locate it with `page.getByRole('dialog')`, not inside the `Racers` group. Step 1 checkboxes are named by the racer plus a last-raced line (`Ada Racer 2025, Team`), so use the default substring match, not `exact`. Step 2 renames the dialog `Review {full name}` and its checkboxes read `"{label}: {value}"` (`Instagram: None` when blank). The roster pill `N of M`, the open-spots row (`3 spots to fill`) and the roster rows live in the `Racers` group. A racer's roster row exists only once they are added, so wait for it there; the row's name is just the full name, so `exact` works on it.

## Technical Debt

The following items were identified during the Rails 8 upgrade and should be addressed when time permits:

1. **`stripe` gem (~> 1.58.0)**: Very outdated version from ~2017. Should be updated to modern stripe-ruby (v10+). This will require updating API calls throughout `lib/stripe_helper.rb` and payment-related code. Test thoroughly with `stripe-ruby-mock`.

2. **`coffee-rails` gem**: CoffeeScript is deprecated. JavaScript assets should be migrated to ES6. Files to convert are in `app/assets/javascripts/`. Can be removed from Gemfile after migration.

3. **`sass-rails` gem (~> 5.0)**: Consider migrating to modern CSS tooling (cssbundling-rails, Propshaft, or Dart Sass). Current stylesheets are in `app/assets/stylesheets/`.

4. **Dependabot PRs to close, not merge**: `codeclimate-test-reporter` 1.0.9 pins `simplecov <= 0.13` (it would downgrade simplecov from 0.22 to 0.3.9), and the `stripe` 18 / `stripe-ruby-mock` 2.5 jump is the item 1 migration above, not a drive-by bump. Routine bumps: `bundle update --minor --conservative <gems>` (the Rails gems are pinned `~> 8.0.0` and must move together).

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
