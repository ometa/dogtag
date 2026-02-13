# Copyright (C) 2017 Devin Breen
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
redis_url = ENV["REDIS_URL"] || "redis://127.0.0.1:6379/0"

redis_config = {
  url: redis_url,
  ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE },
  timeout: 5,
  reconnect_attempts: [0, 0.05, 0.1]
}

Sidekiq.configure_server do |config|
  config.redis = redis_config
  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end
  SidekiqUniqueJobs::Server.configure(config)
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

# password-protect the /sidekiq route

if ENV['SIDEKIQ_USER'] && ENV['SIDEKIQ_PASS']
  require 'sidekiq'
  require 'sidekiq/web'

  Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
    [user, password] == [ENV['SIDEKIQ_USER'], ENV['SIDEKIQ_PASS']]
  end
end
