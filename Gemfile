source 'https://rubygems.org'
ruby "2.5.3"

gem 'bootstrap-sass'
gem 'bootswatch-rails'

group :production do
  gem 'rails_12factor' # 12 factor support for rails (http://12factor.net/)
  gem 'newrelic_rpm'
  gem 'rollbar'
end

gem 'authlogic',  '~> 3.4.6'   # authentication
gem 'cancancan', '~> 1.10'     # authorization, w/ Rails 4.2 support
gem 'role_model', '~> 0.8.2'   # roles

# payments
gem 'stripe', '~> 1.31.0'

gem 'pg', '~> 0.18.4'           # postgres for heroku
gem 'json-schema'               # validate incoming jsonform

# google analytics
gem 'rack-tracker'

# pub/sub
gem 'wisper-activerecord'

gem 'nokogiri', '~> 1.8.1'
gem 'oj'

gem 'rails', '~> 4.2'
gem 'responders' # responds_to support

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.3'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.1'

gem 'haml'
gem 'haml-rails'

gem 'awesome_print'
gem 'httpclient'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
#gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.2'

# workers
gem 'sidekiq'
gem 'sidekiq-failures'
gem 'redis-namespace'

group :development do
  gem 'capistrano'
  gem 'mailcatcher'
  gem 'web-console', '~> 3.0'
end

group :test do
  gem 'test-unit'
  gem 'rspec'
  gem 'rspec-rails'
  gem 'wisper-rspec'
  gem 'webmock'
  gem 'simplecov'
  gem 'stripe-ruby-mock', '~> 2.3.1'
  gem 'codeclimate-test-reporter'
  gem 'zonebie'
  gem 'timecop'
  gem 'faker'
end

group :test, :development do
  gem 'test_after_commit' # required to test wisper pub/sub until rails 5+
  gem 'factory_bot_rails'
  gem 'dotenv-rails'
end

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the app server (heroku)
gem 'unicorn', '~> 5.2'

# Use debugger
# gem 'debugger', group: [:development, :test]
