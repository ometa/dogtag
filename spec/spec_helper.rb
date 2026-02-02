# Copyright (C) 2013 Devin Breen
# This file is part of dogtag <https://github.com/chiditarod/dogtag>.
#
# dogtag is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# dogtag is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with dogtag.  If not, see <http://www.gnu.org/licenses/>.
# Generates code coverage report in /coverage/ when specs are run
require 'simplecov'
SimpleCov.start

ENV["RAILS_ENV"] ||= 'test'

require File.expand_path("../../config/environment", __FILE__)
require 'webmock/rspec'
require "zonebie/rspec"
require 'rspec/rails'
require 'sidekiq/testing'
require 'wisper/rspec/matchers'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.check_all_pending! if defined?(ActiveRecord::Migration)

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.include(Wisper::RSpec::BroadcastMatcher)

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = ["#{::Rails.root}/spec/fixtures"]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  config.infer_spec_type_from_file_location!

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  config.before do
    ActionMailer::Base.deliveries.clear
    Sidekiq::Worker.clear_all
  end

  # whitelist codeclimate.com so test coverage can be reported
  config.after(:suite) do
    WebMock.disable_net_connect!(allow: 'codeclimate.com')
  end
end

# AuthLogic
require 'authlogic/test_case'
include Authlogic::TestCase

# CanCan authorization
require "cancan/matchers"

# Global time constant for use with Timecop
THE_TIME = Time.zone.local(1980, 9, 1, 12, 0, 0)

def login_user!(user)
  expect(user).to_not be_nil
  session = UserSession.create!(user, false)
  expect(session).to be_valid
  session.save
end
