dogtag
======

*dogtag is a Ruby on Rails application that registers user and teams for the annual [CHIditarod](http://chiditarod.org) urban shopping cart race and epic mobile food drive.  The code is 100% open-source, runs on Heroku, and has processed more than $75,000.*

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
- Redis (3.2)
- PostgreSQL (9.4)
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
```

Docker Developer Setup
----------------------

### Build and run all containers

    docker-compose up -d

### Create and Migrate Databases

Inside Container:

    docker-compose run web bundle exec rake db:create db:migrate
    docker-compose run -e RAILS_ENV=test web bundle exec rake db:create db:migrate

Outside Container:

    export DATABASE_URL=postgres://postgres:123abc@localhost:5432
    bundle exec rake db:create db:migrate
    RAILS_ENV=test bundle exec rake db:create db:migrate

### Run the test suite

Inside Container: 

    docker-compose run web bundle exec rspec

Outside Container:

    export DATABASE_URL=postgres://postgres:123abc@localhost:5432
    bundle exec rspec

### Connect to postgres inside container

    docker-compose exec db psql -U postgres

### Restore postgres db from a dump file

```bash
docker cp /local/file.dump $(docker-compose ps -q  db):/file.dump
docker-compose exec db pg_restore -U postgres --verbose --clean --no-acl --no-owner -h localhost -d dogtag_development /file.dump
```

Non-Docker Developer Setup
--------------------------

*__Deprecated.__ Tested on an OSX environment. If you do it in Windows or Linux and send us instructions, we will add them here.*

1. Setup your Ruby environment by installing [Homebrew](https://github.com/Homebrew/homebrew) and [rbenv](https://github.com/rbenv/rbenv).

1. Install the Ruby version specified in `.ruby-version`

1. Install the bundle

        bundle install

1. Export required environment vars

        export STRIPE_PUBLISHABLE_KEY=<...>   # stripe api
        export STRIPE_SECRET_KEY=<...>        # stripe api
        export RAILS_SECRET_TOKEN=<...>       # rails

1. Export optional environment vars

        REDIS_URL=<...>                       # default: redis://127.0.0.1:6379
        CLASSY_CLIENT_ID=<...>                # if you are using classy
        CLASSY_CLIENT_SECRET=<...>            # if you are using classy
        SIDEKIQ_USER=<...>                    # include to protect /sidekiq route behind http basic auth
        SIDEKIQ_PASS=<...>                    # include to protect /sidekiq route behind http basic auth

1. Run back-end services

	*Docker makes it considerably easier to use these back-end services in local development.  Consult the Docker section above vs. installing them manually onto your workstation.*

        redis-server
        postgres -D /usr/local/var/postgres
        bundle exec mailcatcher

1. Run dogtag deamons

        bundle exec sidekiq -t 10 -C ./config/sidekiq.yml
        bundle exec rails s

1. Run the test suite

        bundle exec rspec


Basic Deploy Plan
-----------------
1. Test locally using TEST Stripe credentials.
2. Deploy to a Heroku staging environment using TEST credentials.
3. Deploy to production using PROD credentials.
4. Tail them logs.


Yearly Cycle
------------
Here is an outline of the yearly cycle for using Dogtag with a single event ([CHIditarod](http://www.chiditarod.org), in our case).

1. Do a development cycle to incorporate any new features.
1. Update the jsonform with any new questions and expected responses for the specific race.
1. Launch it all locally, make sure Stripe payments are functioning and a team can finalize their registration successfully.
1. Use mailcatcher to ensure emails are being created and sent.
1. Check that the SSL certificate for dogtag.chiditarod.org is up to date and working
1. Turn on SSL in heroku and apply the cert.
1. Upgrade PostgreSQL if needed
1. Upgrade Rails to pick up security fixes.
