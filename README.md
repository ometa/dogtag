dogtag
======

*dogtag is a Ruby on Rails application that registers user and teams for the annual [CHIditarod](http://chiditarod.org) urban shopping cart race and epic mobile food drive.  The code is 100% open-source, runs on Heroku, and has processed m ore than $75,000.*

![Build Status](https://travis-ci.org/chiditarod/dogtag.svg?branch=master)
[![Test Coverage](https://codeclimate.com/github/chiditarod/dogtag/badges/coverage.svg)](https://codeclimate.com/github/chiditarod/dogtag/coverage)
[![Code Climate](https://codeclimate.com/github/chiditarod/dogtag.png)](https://codeclimate.com/github/chiditarod/dogtag)

Requirements
------------

- App Server like Heroku
- Redis
- PostgreSQL
- SMTP Server

Developer Setup
---------------
*Assumes an OSX environment. If you do it in Windows or Linux, please send us instructions and we will include them.*

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

1. Run local daemons

        redis-server
        postgres -D /usr/local/var/postgres
        bundle exec sidekiq -t 10 -C ./config/sidekiq.yml
        bundle exec mailcatcher
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
