ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

# Prevent EPIPE errors when stdout pipe is closed (e.g., during tests)
$stdout.sync = true
$stderr.sync = true
