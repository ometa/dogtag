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

  API_HOST              = "https://api.classy.org"
  API_VERSION           = "2.0"
  DEFAULT_TIMEOUT       = 3 # seconds
  AUTH_ENDPOINT         = "#{API_HOST}/oauth2/auth"
  BASE_HEADERS          = { 'User-Agent' => 'dogtag' }
  API_HEADERS           = BASE_HEADERS.merge({ 'Content-type' => 'application/json' })

  # Retry configuration
  MAX_RETRIES           = 3
  BASE_RETRY_DELAY      = 1 # seconds
  RETRIABLE_STATUS_CODES = [502, 503, 504].freeze

  def initialize
    fetch_access_token!
  end

  def get_campaign(id)
    get("/campaigns/#{id}")
  end

  def get_member(id_or_email)
    get("/members/#{id_or_email}")
  rescue TransientError
    nil
  end

  # configure a campaign how we like it
  def configure_campaign(campaign_id)
    body = {
      "allow_duplicate_fundraisers" => true
    }
    put("/campaigns/#{campaign_id}", body)
  end

  # create_member calls the classy api and attempts to create a member record and then a supporter record.
  # if this email address aleady has a member record associated with it in classy, the api endpoint will respond with
  # "This email address is already used." and a subsequent call should be made to try creating a supporter record
  # The required fields are first_name, last_name, and email_address
  #
  # https://developers.classy.org/api-docs/v2/index.html#member-member-post
  def create_member(organization_id, first, last, email)
    body = {
      "first_name" => first,
      "last_name" => last,
      "email_address" => email
    }
    post_response("/organizations/#{organization_id}/members", body)
  end

  # create_supporter calls the classy api and attempts to create a supporter record for organization_id.
  # This function is not required if create_member was called with the same arguments and returned 200.
  def create_supporter(organization_id, first, last, email)
    body = {
      "first_name" => first,
      "last_name" => last,
      "email_address" => email
    }
    post_response("/organizations/#{organization_id}/supporters", body)
  end

  # get_supporter will attempt to find a supporter record with email address of 'email'
  # the classy organization 'organization_id'. It will page through each api response until
  # all classy records are exhausted. returns nil if no supporter record was found.
  # NOTE: this process can take a long time.
  def get_supporter(organization_id, email, page=1)
    response = get("/organizations/#{organization_id}/supporters?page=#{page}")
    if response["data"].index{|d| d["email_address"] =~ /#{email}/ } != nil
      return response["data"][response["data"].index{|d| d["email_address"]  =~ /#{email}/ }]
    end
    if response["current_page"] == response["last_page"]
      return nil
    end
    return get_supporter(organization_id, email, page+1)
  end

  # with_supporters allows each page of org supporter records returned
  # from the classy api to be yielded to a block
  def with_supporters(organization_id, page=1, &block)
    response = get("/organizations/#{organization_id}/supporters?page=#{page}")
    yield(response["data"])
    if response["current_page"] == response["last_page"]
      return nil
    end
    return with_supporters(organization_id, page+1, &block)
  end

  def get_fundraising_team(team_id)
    get("/fundraising-teams/#{team_id}")
  rescue TransientError
    nil
  end

  # https://developers.classy.org/api-docs/v2/index.html#fundraising-teams-fundraising-team-post
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
  rescue TransientError
    nil
  end

  def create_fundraising_page(team_id, member_id, title, goal)
    body = {
      "member_id" => member_id,
      "title" => title,
      "goal" => goal
    }
    post("/fundraising-teams/#{team_id}/fundraising-pages", body)
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

  def post_response(uri, body=nil)
    with_token do |args|
      args[:body] = body.to_json if body.present?
      wrap(:post, "/#{API_VERSION}#{uri}", args)
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
  def wrap(verb, uri, args={})
    args[:header] = {} unless args[:header].present?
    args[:header]['User-Agent'] = 'dogtag'
    args[:follow_redirect] = true

    http = HTTPClient.new
    http.connect_timeout = DEFAULT_TIMEOUT
    http.send(verb, "#{API_HOST}#{uri}", args)
  end

  # docs for httpclient gem: http://www.rubydoc.info/gems/httpclient/HTTPClient
  # for get, specify query in args, e.g.
  #   query: { 'foo' => 'bar', 'baz' => 'omg' }
  # for post, specify a body in args
  #
  # args - args to pass to http_client
  #
  # Includes retry logic with exponential backoff for:
  # - HTTPClient timeout errors (ConnectTimeoutError, ReceiveTimeoutError, etc.)
  # - Retriable HTTP status codes (502, 503, 504)
  def wrapper(verb, uri, args={})
    args[:header] = {} unless args[:header].present?
    args[:header]['User-Agent'] = 'dogtag'
    args[:follow_redirect] = true

    retries = 0
    begin
      http = HTTPClient.new
      http.connect_timeout = DEFAULT_TIMEOUT
      response = http.send(verb, "#{API_HOST}#{uri}", args)

      unless response.ok?
        if retriable_status?(response.status) && retries < MAX_RETRIES
          retries += 1
          sleep_with_backoff(retries)
          raise RetriableError.new("#{response.status}: #{response.body}")
        end
        raise TransientError.new("#{response.status}: #{response.body}")
      end

      JSON.parse(response.body)
    rescue RetriableError
      retry
    rescue HTTPClient::TimeoutError
      if retries < MAX_RETRIES
        retries += 1
        sleep_with_backoff(retries)
        retry
      end
      raise
    end
  end

  def retriable_status?(status)
    RETRIABLE_STATUS_CODES.include?(status)
  end

  def sleep_with_backoff(retry_count)
    # Exponential backoff with jitter: base_delay * 2^(retry-1) + random jitter
    delay = BASE_RETRY_DELAY * (2 ** (retry_count - 1)) + rand(0.0..0.5)
    sleep(delay)
  end

  # Internal error class used to trigger retry logic
  class RetriableError < StandardError; end
end
