dogtag
======

*dogtag is a Ruby on Rails application that registers user and teams for the annual [CHIditarod](http://chiditarod.org) urban shopping cart race and epic mobile food drive.  The code is 100% open-source, runs on Heroku, and has processed more than $100,000.*

![Build Status](https://travis-ci.org/chiditarod/dogtag.svg?branch=master)
[![Test Coverage](https://codeclimate.com/github/chiditarod/dogtag/badges/coverage.svg)](https://codeclimate.com/github/chiditarod/dogtag/coverage)
[![Code Climate](https://codeclimate.com/github/chiditarod/dogtag.png)](https://codeclimate.com/github/chiditarod/dogtag)

Integrations
--------
- Payments/Refunds via the Stripe API
- Fundraising campaign automation via the Classy API

Requirements
------------
- App Server like Heroku
- Redis
- PostgreSQL
- SMTP Server

Runtime Environment Variables
-----------------------------

```
DATABASE_URL=postgres://postgres:123abc@localhost:5432
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
CLASSY_CLIENT_ID=...           # optional
CLASSY_CLIENT_SECRET=...       # optional
ROLLBAR_ACCESS_TOKEN=...       # optional
SKIP_VALIDATION=1              # optional; include to skip checking for required runtime variables, useful for running migrations.
```

## Custom questions using jsonform

Each race has a `jsonform` field. This field can contain a [jsonform](https://github.com/jsonform/jsonform) schema that is consumed and rendered as questions to the end-user during their team signup. Their responses are then saved into their team record and are included when exporting a CSV.

- __NOTE:__ There's a hack that requires addition to `HACK_PARAM_WHITELIST` any time a new jsonform question is added.  See [https://github.com/chiditarod/dogtag/issues/40](https://github.com/chiditarod/dogtag/issues/40).
- For example jsonform data, see [github](https://github.com/chiditarod/dogtag/tree/master/examples/jsonform)

## Developer Setup

*Tested against MacOS Mojave (10.14.2)*

### Prerequisites

- [Xcode](https://itunes.apple.com/us/app/xcode/id497799835)
- [Docker](https://docs.pie.apple.com/artifactory/docker.html)
- [Homebrew](https://brew.sh/)

### Install Ruby

```bash
brew install rbenv
rbenv install $(cat .ruby-version)
gem install bundler
```

### Install Gems

```bash
brew install libffi libpq
export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/usr/local/opt/libffi/lib/pkgconfig"
bundle config --local build.ffi --with-ldflags="-L/usr/local/opt/libffi/lib"
bundle config --local build.pg --with-opt-dir="/usr/local/opt/libpq"
```

### Build and run all containers

This will also create the `dogtag_test` and `dogtag_development` databases.

    docker-compose up -d

### Create an `.env` file for local development

This file is used when booting Rails outside of Docker.  Customize `.env` with `STRIPE_PUBLISHABLE_KEY` and `STRIPE_PUBLISHABLE_KEY` entries, which are currently required to boot the app.

```bash
cp .env.example .env
```

### Create and Migrate Databases

Via docker:

    docker-compose run web bundle exec rake db:migrate
    docker-compose run -e RAILS_ENV=test web bundle exec rake db:migraten

Or via the command lineo

    bundle exec rake db:migrate
    RAILS_ENV=test bundle exec rake db:migrate

### Run the test suite

    docker-compose run web bundle exec rspec   # from within the container
    bundle exec rspec                          # or from the console


## Useful Commands

### Connect to postgres inside container

    docker-compose exec db psql -U postgres

### Restore postgres db from a dump file

```bash
docker cp /local/file.dump $(docker-compose ps -q  db):/file.dump
docker-compose exec db pg_restore -U postgres --verbose --clean --no-acl --no-owner -h localhost -d dogtag_development /file.dump
```

## Basic Deploy Plan

1. Test locally using TEST Stripe credentials.
2. Deploy to a Heroku staging environment using TEST credentials.
3. Deploy to production using PROD credentials.
4. Tail them logs.

## Yearly Cycle

Here is an outline of the yearly cycle for using Dogtag with a single event ([CHIditarod](http://www.chiditarod.org), in our case).

1. Do a development cycle to incorporate any new features.
1. Update the jsonform with any new questions and expected responses for the specific race.
1. Launch it all locally, make sure Stripe payments are functioning and a team can finalize their registration successfully.
1. Use mailcatcher to ensure emails are being created and sent.
1. Check that the SSL certificate for dogtag.chiditarod.org is up to date and working
1. Turn on SSL in heroku and apply the cert.
1. Upgrade PostgreSQL if needed
1. Upgrade Rails to pick up security fixes.
