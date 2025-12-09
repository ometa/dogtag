ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require 'logger' # Required for Rails 6.0+ on Ruby 2.7
# require 'bootsnap/setup' # Speed up boot time by caching expensive operations. # Temporarily disabled
