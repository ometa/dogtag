source 'https://rubygems.org'
ruby "2.3.0"

# -------------------------------------------------------
# rails-skeleton

gem 'bootstrap-sass'
gem 'bootswatch-rails'

group :production do
  # 12 factor support for rails (http://12factor.net/)
  gem 'rails_12factor'
  gem 'newrelic_rpm'
end

# -------------------------------------------------------
# BEGIN dogtag gems

gem 'authlogic',  '~> 3.4.6'   # authentication
gem 'cancan',     '~> 1.6.10'  # authorization
gem 'role_model', '~> 0.8.2'   # roles

# payments
#gem 'stripe', :git => 'https://github.com/stripe/stripe-ruby'
gem 'stripe', '~> 1.31.0'

gem 'pg', '~> 0.18.4'           # postgres for heroku
gem 'json-schema'               # validate incoming jsonform

# google analytics
gem 'rack-tracker'

# ruby pubsub (observer pattern replacement)
gem 'wisper'
gem 'wisper-activerecord'

# END dogtag gems
# -------------------------------------------------------

gem 'rails', '~> 4.0.2'
#gem 'rails', '4.1.6'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.3'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.1'

gem 'haml'
gem 'haml-rails'

gem 'awesome_print'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
#gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.2'

group :development do
  gem 'capistrano'
  gem 'mailcatcher'
  gem 'guard-rspec', require: false
end

group :test do
  gem 'timecop'
  gem 'webmock'
  gem 'simplecov'
  gem 'stripe-ruby-mock', '~> 2.2.1'
  gem 'codeclimate-test-reporter'
  gem 'wisper-rspec'
  gem 'test_after_commit' # needed until Rails 5 arrives (https://github.com/grosser/test_after_commit)
end

group :test, :development do
  gem 'test-unit'
  gem 'rspec', '~> 2.14.0'
  gem 'rspec-rails'
  gem 'factory_girl_rails', '4.3.0'
end

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the app server (heroku)
#gem 'unicorn', '4.8.0'
gem 'unicorn', '5.0.1'

# Use debugger
# gem 'debugger', group: [:development, :test]
