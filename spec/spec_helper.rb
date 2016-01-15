# CodeClimate coverage
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

# Generates code coverage report in /coverage/ when specs are run
require 'simplecov'
SimpleCov.start 'rails'

require 'wisper/rspec/matchers'

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

RSpec.configure do |config|
  # wisper rspec helpers
  config.include(Wisper::RSpec::BroadcastMatcher)

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  # stub Time.now for all specs
  #config.before(:each) do
    #@now_stub = Time.parse("01/01/2010 10:00")
    #allow(Time).to receive(:now).and_return(@now_stub)
  #end

  # whitelist codeclimate.com so test coverage can be reported
  config.after(:suite) do
    WebMock.disable_net_connect!(:allow => 'codeclimate.com')
  end
end

# AuthLogic
require 'authlogic/test_case'
include Authlogic::TestCase

# CanCan authorization
require "cancan/matchers"

# Global time constant for use with Timecop
THE_TIME = Time.local(1980, 9, 1, 12, 0, 0)

def mock_login!(user)
  expect(user).to_not be_nil
  session = UserSession.create!(user, false)
  expect(session).to be_valid
  session.save
end

def mock_emailer!
  ActionMailer::Base.delivery_method = :test
  ActionMailer::Base.perform_deliveries = true
  ActionMailer::Base.deliveries = []
end

def reset_mailer!
  ActionMailer::Base.deliveries.clear
end
