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
require 'spec_helper'

describe ClassyClient do

  before do
    # TODO: kill timecop with fire and paradoxes
    Timecop.freeze(THE_TIME)
    ENV['CLASSY_CLIENT_ID'] = 'some_id'
    ENV['CLASSY_CLIENT_SECRET'] = 'some_secret'
  end

  after { Timecop.return }

  shared_examples "authentication is successful" do
    let(:valid_auth_response) do
      {
        'access_token' => '123abc',
        'token_type' => 'bearer',
        'expires_in' => 3600
      }.to_json
    end

    before do
      stub_request(:post, ClassyClient::AUTH_ENDPOINT).to_return(status: 200, body: valid_auth_response)
    end
  end

  describe '#initialize' do

    %w(CLASSY_CLIENT_ID CLASSY_CLIENT_SECRET).each do |env_var|

      context "when class environment variable #{env_var} is not provided" do
        before do
          ENV[env_var] = nil
        end

        it "raises an error" do
          expect { ClassyClient.new }.to raise_error(ArgumentError)
        end
      end
    end

    context "when authentication succeeds" do
      include_examples "authentication is successful"

      it 'sets up the classy api authentication and sets the token expiry' do
        cc = ClassyClient.new
        expect(cc.access_token).to eq('123abc')
        expect(cc.token_type).to eq('bearer')
        expect(cc.expires_at).to eq(THE_TIME + 3600.seconds)
      end
    end
  end

  %i(get post put).each do |verb|

    describe "##{verb}" do

      include_examples "authentication is successful"
      let(:classy_url) { "#{ClassyClient::API_HOST}/#{ClassyClient::API_VERSION}" }

      context "when response is not 'ok'" do
        before do
          stub_request(verb, "#{classy_url}/foo").to_return(status: 404)
        end

        it "raises a TransientError" do
          expect do
            ClassyClient.new.send(verb, "/foo")
          end.to raise_error(TransientError)
        end
      end

      context "when authentication token has expired" do
        let(:future)     { 3601 }
        let(:new_expiry) { THE_TIME + future.seconds + 3600.seconds }

        it "re-authenticates and updates the expiry" do
          cc = ClassyClient.new
          Timecop.travel(future) do
            stub_request(verb, "#{classy_url}/foo").to_return(status: 200, body: {'foo' => 'bar'}.to_json)
            cc.send(verb, "/foo")
            # there is probably a cleaner way to do this
            expect(cc.expires_at.to_i).to eq(new_expiry.to_i)
          end
        end
      end
    end
  end

  describe "#get_campaign" do
    include_examples "authentication is successful"
    let(:classy_url) { "#{ClassyClient::API_HOST}/#{ClassyClient::API_VERSION}" }
    let(:campaign_data) { { "id" => 12345, "name" => "Test Campaign" } }

    it "returns campaign data" do
      stub_request(:get, "#{classy_url}/campaigns/12345").to_return(status: 200, body: campaign_data.to_json)
      result = ClassyClient.new.get_campaign(12345)
      expect(result).to eq(campaign_data)
    end

    it "raises TransientError on failure" do
      stub_request(:get, "#{classy_url}/campaigns/12345").to_return(status: 500, body: "Internal Server Error")
      expect { ClassyClient.new.get_campaign(12345) }.to raise_error(TransientError)
    end
  end

  describe "#get_member" do
    include_examples "authentication is successful"
    let(:classy_url) { "#{ClassyClient::API_HOST}/#{ClassyClient::API_VERSION}" }
    let(:member_data) { { "id" => 111, "email_address" => "test@example.com" } }

    it "returns member data on success" do
      stub_request(:get, "#{classy_url}/members/111").to_return(status: 200, body: member_data.to_json)
      result = ClassyClient.new.get_member(111)
      expect(result).to eq(member_data)
    end

    it "returns member data when queried by email" do
      stub_request(:get, "#{classy_url}/members/test@example.com").to_return(status: 200, body: member_data.to_json)
      result = ClassyClient.new.get_member("test@example.com")
      expect(result).to eq(member_data)
    end

    it "returns nil on TransientError (member not found)" do
      stub_request(:get, "#{classy_url}/members/999").to_return(status: 404, body: "Not Found")
      result = ClassyClient.new.get_member(999)
      expect(result).to be_nil
    end
  end

  describe "#configure_campaign" do
    include_examples "authentication is successful"
    let(:classy_url) { "#{ClassyClient::API_HOST}/#{ClassyClient::API_VERSION}" }
    let(:response_data) { { "id" => 12345, "allow_duplicate_fundraisers" => true } }

    it "sends PUT request with correct body" do
      stub = stub_request(:put, "#{classy_url}/campaigns/12345")
        .with(body: { "allow_duplicate_fundraisers" => true }.to_json)
        .to_return(status: 200, body: response_data.to_json)

      ClassyClient.new.configure_campaign(12345)
      expect(stub).to have_been_requested
    end
  end

  describe "#create_member" do
    include_examples "authentication is successful"
    let(:classy_url) { "#{ClassyClient::API_HOST}/#{ClassyClient::API_VERSION}" }
    let(:response_data) { { "id" => 111, "first_name" => "John", "last_name" => "Doe", "email_address" => "john@example.com" } }

    it "creates a member with correct parameters" do
      stub = stub_request(:post, "#{classy_url}/organizations/999/members")
        .with(body: { "first_name" => "John", "last_name" => "Doe", "email_address" => "john@example.com" }.to_json)
        .to_return(status: 200, body: response_data.to_json)

      ClassyClient.new.create_member(999, "John", "Doe", "john@example.com")
      expect(stub).to have_been_requested
    end
  end

  describe "#create_supporter" do
    include_examples "authentication is successful"
    let(:classy_url) { "#{ClassyClient::API_HOST}/#{ClassyClient::API_VERSION}" }
    let(:response_data) { { "id" => 222, "first_name" => "Jane", "last_name" => "Doe", "email_address" => "jane@example.com" } }

    it "creates a supporter with correct parameters" do
      stub = stub_request(:post, "#{classy_url}/organizations/999/supporters")
        .with(body: { "first_name" => "Jane", "last_name" => "Doe", "email_address" => "jane@example.com" }.to_json)
        .to_return(status: 200, body: response_data.to_json)

      ClassyClient.new.create_supporter(999, "Jane", "Doe", "jane@example.com")
      expect(stub).to have_been_requested
    end
  end

  describe "#get_supporter" do
    include_examples "authentication is successful"
    let(:classy_url) { "#{ClassyClient::API_HOST}/#{ClassyClient::API_VERSION}" }

    context "when supporter is found on first page" do
      let(:page1_response) do
        {
          "data" => [
            { "id" => 1, "email_address" => "other@example.com" },
            { "id" => 2, "email_address" => "target@example.com" }
          ],
          "current_page" => 1,
          "last_page" => 3
        }
      end

      it "returns the supporter record" do
        stub_request(:get, "#{classy_url}/organizations/999/supporters?page=1")
          .to_return(status: 200, body: page1_response.to_json)

        result = ClassyClient.new.get_supporter(999, "target@example.com")
        expect(result["id"]).to eq(2)
        expect(result["email_address"]).to eq("target@example.com")
      end
    end

    context "when supporter is found on later page" do
      let(:page1_response) do
        {
          "data" => [{ "id" => 1, "email_address" => "other@example.com" }],
          "current_page" => 1,
          "last_page" => 2
        }
      end
      let(:page2_response) do
        {
          "data" => [{ "id" => 2, "email_address" => "target@example.com" }],
          "current_page" => 2,
          "last_page" => 2
        }
      end

      it "paginates and returns the supporter record" do
        stub_request(:get, "#{classy_url}/organizations/999/supporters?page=1")
          .to_return(status: 200, body: page1_response.to_json)
        stub_request(:get, "#{classy_url}/organizations/999/supporters?page=2")
          .to_return(status: 200, body: page2_response.to_json)

        result = ClassyClient.new.get_supporter(999, "target@example.com")
        expect(result["id"]).to eq(2)
      end
    end

    context "when supporter is not found" do
      let(:page1_response) do
        {
          "data" => [{ "id" => 1, "email_address" => "other@example.com" }],
          "current_page" => 1,
          "last_page" => 1
        }
      end

      it "returns nil" do
        stub_request(:get, "#{classy_url}/organizations/999/supporters?page=1")
          .to_return(status: 200, body: page1_response.to_json)

        result = ClassyClient.new.get_supporter(999, "notfound@example.com")
        expect(result).to be_nil
      end
    end
  end

  describe "#with_supporters" do
    include_examples "authentication is successful"
    let(:classy_url) { "#{ClassyClient::API_HOST}/#{ClassyClient::API_VERSION}" }

    context "when there is one page of results" do
      let(:page1_response) do
        {
          "data" => [
            { "id" => 1, "email_address" => "user1@example.com" },
            { "id" => 2, "email_address" => "user2@example.com" }
          ],
          "current_page" => 1,
          "last_page" => 1
        }
      end

      it "yields the data to the block" do
        stub_request(:get, "#{classy_url}/organizations/999/supporters?page=1")
          .to_return(status: 200, body: page1_response.to_json)

        yielded_data = []
        ClassyClient.new.with_supporters(999) { |data| yielded_data << data }
        expect(yielded_data.length).to eq(1)
        expect(yielded_data.first.length).to eq(2)
      end
    end

    context "when there are multiple pages" do
      let(:page1_response) do
        {
          "data" => [{ "id" => 1, "email_address" => "user1@example.com" }],
          "current_page" => 1,
          "last_page" => 2
        }
      end
      let(:page2_response) do
        {
          "data" => [{ "id" => 2, "email_address" => "user2@example.com" }],
          "current_page" => 2,
          "last_page" => 2
        }
      end

      it "paginates and yields each page" do
        stub_request(:get, "#{classy_url}/organizations/999/supporters?page=1")
          .to_return(status: 200, body: page1_response.to_json)
        stub_request(:get, "#{classy_url}/organizations/999/supporters?page=2")
          .to_return(status: 200, body: page2_response.to_json)

        yielded_data = []
        ClassyClient.new.with_supporters(999) { |data| yielded_data.concat(data) }
        expect(yielded_data.length).to eq(2)
        expect(yielded_data.map { |d| d["id"] }).to eq([1, 2])
      end
    end

    context "when API returns an error" do
      it "raises TransientError" do
        stub_request(:get, "#{classy_url}/organizations/999/supporters?page=1")
          .to_return(status: 503, body: '{"error":"Service temporarily unavailable"}')

        expect do
          ClassyClient.new.with_supporters(999) { |data| }
        end.to raise_error(TransientError, /503/)
      end
    end
  end

  describe "#get_fundraising_team" do
    include_examples "authentication is successful"
    let(:classy_url) { "#{ClassyClient::API_HOST}/#{ClassyClient::API_VERSION}" }
    let(:team_data) { { "id" => 555, "name" => "Test Team" } }

    it "returns team data on success" do
      stub_request(:get, "#{classy_url}/fundraising-teams/555").to_return(status: 200, body: team_data.to_json)
      result = ClassyClient.new.get_fundraising_team(555)
      expect(result).to eq(team_data)
    end

    it "returns nil on TransientError" do
      stub_request(:get, "#{classy_url}/fundraising-teams/555").to_return(status: 404, body: "Not Found")
      result = ClassyClient.new.get_fundraising_team(555)
      expect(result).to be_nil
    end
  end

  describe "#create_fundraising_team" do
    include_examples "authentication is successful"
    let(:classy_url) { "#{ClassyClient::API_HOST}/#{ClassyClient::API_VERSION}" }
    let(:response_data) { { "id" => 555, "name" => "My Team" } }

    it "creates a fundraising team with correct parameters" do
      expected_body = {
        "name" => "My Team",
        "description" => "Team description",
        "team_lead_id" => 111,
        "team_captain_id" => 111,
        "goal" => 1000
      }

      stub = stub_request(:post, "#{classy_url}/campaigns/12345/fundraising-teams")
        .with(body: expected_body.to_json)
        .to_return(status: 200, body: response_data.to_json)

      ClassyClient.new.create_fundraising_team(12345, "My Team", "Team description", 111, 1000)
      expect(stub).to have_been_requested
    end
  end

  describe "#get_fundraising_page" do
    include_examples "authentication is successful"
    let(:classy_url) { "#{ClassyClient::API_HOST}/#{ClassyClient::API_VERSION}" }
    let(:page_data) { { "id" => 777, "title" => "My Fundraising Page" } }

    it "returns page data on success" do
      stub_request(:get, "#{classy_url}/fundraising-pages/777").to_return(status: 200, body: page_data.to_json)
      result = ClassyClient.new.get_fundraising_page(777)
      expect(result).to eq(page_data)
    end

    it "returns nil on TransientError" do
      stub_request(:get, "#{classy_url}/fundraising-pages/777").to_return(status: 404, body: "Not Found")
      result = ClassyClient.new.get_fundraising_page(777)
      expect(result).to be_nil
    end
  end

  describe "#create_fundraising_page" do
    include_examples "authentication is successful"
    let(:classy_url) { "#{ClassyClient::API_HOST}/#{ClassyClient::API_VERSION}" }
    let(:response_data) { { "id" => 777, "title" => "My Page" } }

    it "creates a fundraising page with correct parameters" do
      expected_body = {
        "member_id" => 111,
        "title" => "My Page",
        "goal" => 500
      }

      stub = stub_request(:post, "#{classy_url}/fundraising-teams/555/fundraising-pages")
        .with(body: expected_body.to_json)
        .to_return(status: 200, body: response_data.to_json)

      ClassyClient.new.create_fundraising_page(555, 111, "My Page", 500)
      expect(stub).to have_been_requested
    end
  end

  describe "HTTP client errors" do
    include_examples "authentication is successful"
    let(:classy_url) { "#{ClassyClient::API_HOST}/#{ClassyClient::API_VERSION}" }

    context "when HTTPClient raises TimeoutError" do
      it "retries and eventually raises the error after max retries" do
        stub_request(:get, "#{classy_url}/campaigns/12345").to_timeout

        client = ClassyClient.new
        allow(client).to receive(:sleep_with_backoff)

        expect do
          client.get_campaign(12345)
        end.to raise_error(HTTPClient::TimeoutError)

        expect(client).to have_received(:sleep_with_backoff).exactly(ClassyClient::MAX_RETRIES).times
      end
    end

    context "when API returns 502 Bad Gateway" do
      it "retries and eventually raises TransientError after max retries" do
        stub_request(:get, "#{classy_url}/campaigns/12345")
          .to_return(status: 502, body: "Bad Gateway")

        client = ClassyClient.new
        allow(client).to receive(:sleep_with_backoff)

        expect do
          client.get_campaign(12345)
        end.to raise_error(TransientError, /502/)

        expect(client).to have_received(:sleep_with_backoff).exactly(ClassyClient::MAX_RETRIES).times
      end
    end

    context "when API returns 503 Service Unavailable" do
      it "retries and eventually raises TransientError after max retries" do
        stub_request(:get, "#{classy_url}/campaigns/12345")
          .to_return(status: 503, body: '{"error":"Service temporarily unavailable"}')

        client = ClassyClient.new
        allow(client).to receive(:sleep_with_backoff)

        expect do
          client.get_campaign(12345)
        end.to raise_error(TransientError, /503/)

        expect(client).to have_received(:sleep_with_backoff).exactly(ClassyClient::MAX_RETRIES).times
      end
    end
  end

  describe "retry behavior" do
    include_examples "authentication is successful"
    let(:classy_url) { "#{ClassyClient::API_HOST}/#{ClassyClient::API_VERSION}" }
    let(:campaign_data) { { "id" => 12345, "name" => "Test Campaign" } }

    context "when 503 error recovers on retry" do
      it "succeeds after transient failure" do
        stub_request(:get, "#{classy_url}/campaigns/12345")
          .to_return(status: 503, body: '{"error":"Service temporarily unavailable"}')
          .then.to_return(status: 200, body: campaign_data.to_json)

        client = ClassyClient.new
        allow(client).to receive(:sleep_with_backoff)

        result = client.get_campaign(12345)
        expect(result).to eq(campaign_data)
        expect(client).to have_received(:sleep_with_backoff).once
      end
    end

    context "when timeout recovers on retry" do
      it "succeeds after transient timeout" do
        stub_request(:get, "#{classy_url}/campaigns/12345")
          .to_timeout
          .then.to_return(status: 200, body: campaign_data.to_json)

        client = ClassyClient.new
        allow(client).to receive(:sleep_with_backoff)

        result = client.get_campaign(12345)
        expect(result).to eq(campaign_data)
        expect(client).to have_received(:sleep_with_backoff).once
      end
    end

    context "when 502 error recovers after multiple retries" do
      it "succeeds after multiple transient failures" do
        stub_request(:get, "#{classy_url}/campaigns/12345")
          .to_return(status: 502, body: "Bad Gateway")
          .then.to_return(status: 502, body: "Bad Gateway")
          .then.to_return(status: 200, body: campaign_data.to_json)

        client = ClassyClient.new
        allow(client).to receive(:sleep_with_backoff)

        result = client.get_campaign(12345)
        expect(result).to eq(campaign_data)
        expect(client).to have_received(:sleep_with_backoff).twice
      end
    end

    context "when 504 Gateway Timeout occurs" do
      it "retries on 504 status code" do
        stub_request(:get, "#{classy_url}/campaigns/12345")
          .to_return(status: 504, body: "Gateway Timeout")
          .then.to_return(status: 200, body: campaign_data.to_json)

        client = ClassyClient.new
        allow(client).to receive(:sleep_with_backoff)

        result = client.get_campaign(12345)
        expect(result).to eq(campaign_data)
        expect(client).to have_received(:sleep_with_backoff).once
      end
    end

    context "when non-retriable error occurs" do
      it "does not retry on 400 Bad Request" do
        stub_request(:get, "#{classy_url}/campaigns/12345")
          .to_return(status: 400, body: "Bad Request")

        client = ClassyClient.new
        allow(client).to receive(:sleep_with_backoff)

        expect { client.get_campaign(12345) }.to raise_error(TransientError, /400/)
        expect(client).not_to have_received(:sleep_with_backoff)
      end

      it "does not retry on 401 Unauthorized" do
        stub_request(:get, "#{classy_url}/campaigns/12345")
          .to_return(status: 401, body: "Unauthorized")

        client = ClassyClient.new
        allow(client).to receive(:sleep_with_backoff)

        expect { client.get_campaign(12345) }.to raise_error(TransientError, /401/)
        expect(client).not_to have_received(:sleep_with_backoff)
      end

      it "does not retry on 404 Not Found" do
        stub_request(:get, "#{classy_url}/campaigns/12345")
          .to_return(status: 404, body: "Not Found")

        client = ClassyClient.new
        allow(client).to receive(:sleep_with_backoff)

        expect { client.get_campaign(12345) }.to raise_error(TransientError, /404/)
        expect(client).not_to have_received(:sleep_with_backoff)
      end

      it "does not retry on 500 Internal Server Error" do
        stub_request(:get, "#{classy_url}/campaigns/12345")
          .to_return(status: 500, body: "Internal Server Error")

        client = ClassyClient.new
        allow(client).to receive(:sleep_with_backoff)

        expect { client.get_campaign(12345) }.to raise_error(TransientError, /500/)
        expect(client).not_to have_received(:sleep_with_backoff)
      end
    end

    context "exponential backoff" do
      it "calls sleep_with_backoff with incrementing retry count" do
        stub_request(:get, "#{classy_url}/campaigns/12345")
          .to_return(status: 503, body: "Service Unavailable")

        client = ClassyClient.new
        allow(client).to receive(:sleep_with_backoff)

        expect { client.get_campaign(12345) }.to raise_error(TransientError)

        expect(client).to have_received(:sleep_with_backoff).with(1).ordered
        expect(client).to have_received(:sleep_with_backoff).with(2).ordered
        expect(client).to have_received(:sleep_with_backoff).with(3).ordered
      end
    end
  end
end
