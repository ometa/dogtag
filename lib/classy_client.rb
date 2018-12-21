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
class ClassyClient

  attr_reader :access_token, :token_type, :expires_at

  API_HOST        = "https://api.classy.org"
  API_VERSION     = "2.0"
  DEFAULT_TIMEOUT = 5 # seconds
  AUTH_ENDPOINT   = "#{API_HOST}/oauth2/auth"
  BASE_HEADERS    = { 'User-Agent' => 'dogtag' }
  API_HEADERS     = BASE_HEADERS.merge({ 'Content-type' => 'application/json' })

  def initialize
    fetch_access_token!
  end

  def get_campaign(id)
    get("/campaigns/#{id}")
  end

  def get_member(id_or_email)
    get("/members/#{id_or_email}")
  rescue ApiError
    nil
  end

  # configure a campaign how we like it
  def configure_campaign(campaign_id)
    body = {
      "allow_duplicate_fundraisers" => true
    }
    put("/campaigns/#{campaign_id}", body)
  end

  def create_member(organization_id, first, last, email)
    # only the required things
    body = {
      "first_name" => first,
      "last_name" => last,
      "email_address" => email,
      "date_of_birth" => "",
      "gender" => ""
    }
    post("/organizations/#{organization_id}/members", body)
  end

  def get_fundraising_team(team_id)
    get("/fundraising-teams/#{team_id}")
  rescue ApiError
    nil
  end

  def create_fundraising_team(campaign_id, name, description, team_lead_id, goal)
    # only the required things
    body = {
      "name" => name,
      "description" => description,
      "team_lead_id" => team_lead_id,
      "team_captain_id" => team_lead_id,
      "goal" => goal
    }
    post("/campaigns/#{campaign_id}/fundraising-teams", body)
  end

  def get_fundraising_page(page_id)
    get("/fundraising-pages/#{page_id}")
  rescue ApiError
    nil
  end

  def create_fundraising_page(title, goal, started_at)
    body = {
      "title" => title,
      "goal" => goal,
      "started_at" => started_at
    }
    put("/fundraising-pages", body)
  end

  def transfer_fundraising_page_to_team(page_id, team_id)
    body = {
      "fundraising_team_id" => team_id
    }
    post("/fundraising-pages/#{page_id}/transfers", body)
  end

  private

  def fetch_access_token!
    unless ENV['CLASSY_CLIENT_ID'] && ENV['CLASSY_CLIENT_SECRET']
      raise ArgumentError, "Must provide 'CLASSY_CLIENT_ID' and 'CLASSY_CLIENT_SECRET' environment variables to use Classy"
    end

    credentials = {
      'grant_type'    => 'client_credentials',
      'client_id'     => ENV['CLASSY_CLIENT_ID'],
      'client_secret' => ENV['CLASSY_CLIENT_SECRET']
    }

    client = HTTPClient.new
    client.connect_timeout = DEFAULT_TIMEOUT
    response = wrapper(:post, "/oauth2/auth", { body: credentials })

    @access_token = response['access_token']
    @token_type = response['token_type']
    @expires_at = Time.now + response['expires_in'].seconds
  end

  def token_expired?
    Time.now > @expires_at
  end

  def with_token
    fetch_access_token! if token_expired?
    args = { header: API_HEADERS }
    args[:header]['Authorization'] = "#{@token_type} #{@access_token}"
    yield(args)
  end

  def get(uri, query={})
    with_token do |args|
      args[:query] = query if query.present?
      wrapper(:get, "/#{API_VERSION}#{uri}", args)
    end
  end

  def post(uri, body=nil)
    with_token do |args|
      args[:body] = body.to_json if body.present?
      wrapper(:post, "/#{API_VERSION}#{uri}", args)
    end
  end

  def put(uri, body={})
    with_token do |args|
      args[:body] = body.to_json if body.present?
      wrapper(:put, "/#{API_VERSION}#{uri}", args)
    end
  end

  # docs for httpclient gem: http://www.rubydoc.info/gems/httpclient/HTTPClient
  # for get, specify query in args, e.g.
  #   query: { 'foo' => 'bar', 'baz' => 'omg' }
  # for post, specify a body in args
  #
  # args - args to pass to http_client
  def wrapper(verb, uri, args={})
    args[:header] = {} unless args[:header].present?
    args[:header]['User-Agent'] = 'dogtag'
    args[:follow_redirect] = true

    http = HTTPClient.new
    http.connect_timeout = DEFAULT_TIMEOUT
    response = http.send(verb, "#{API_HOST}#{uri}", args)

    unless response.ok?
      raise ApiError.new("#{response.status}: #{response.body}: #{response.headers}")
    end

    JSON.parse(response.body)
  end

  class ApiError < StandardError
  end
end
