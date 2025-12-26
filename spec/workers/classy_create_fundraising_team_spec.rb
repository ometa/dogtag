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

# these tests call worker.perform which invokes .run via the common worker

describe Workers::ClassyCreateFundraisingTeam do

  let(:worker) { Workers::ClassyCreateFundraisingTeam.new }

  # this stubs out an authenticated classy client
  let(:valid_cc) do
    ENV['CLASSY_CLIENT_ID'] = 'some_id'
    ENV['CLASSY_CLIENT_SECRET'] = 'some_secret'
    valid_auth = {
      'access_token' => 'abc123',
      'token_type' => 'bearer',
      'expires_in' => 3600
    }
    stub_request(:post, ClassyClient::AUTH_ENDPOINT).to_return(status: 200, body: valid_auth.to_json)
    ClassyClient.new
  end

  describe "#run" do

    before do
      allow(worker).to receive(:log).with("received", any_args)
    end

    context 'when team already has a classy id' do
      let(:team) { FactoryBot.create :team, :with_classy_id }
      let(:log) do
        {
          job: {'team_id' => team.id},
          message: "Team id: #{team.id} already has a classy team fundraiser id of #{team.classy_id}"
        }
      end

      it 'logs complete and returns' do
        expect(worker).to receive(:log).with("complete", log)
        worker.perform({'team_id' => team.id})
      end
    end

    context 'when race has no classy campaign id' do
      let(:team) { FactoryBot.create :team }
      let(:log) do
        {
          message: "No classy campaign id set for race id: #{team.race.id}, therefore we cannot create a fundraising team"
        }
      end

      it 'logs op-op and returns' do
        expect(worker).to receive(:log).with("no-op", log)
        worker.perform({'team_id' => team.id})
      end
    end

    context 'when race has no classy default goal' do
      let(:race) { FactoryBot.create :race, classy_campaign_id: 12345 }
      let(:team) { FactoryBot.create :team, race: race }
      let(:log) do
        {
          message: "No classy default fundraising goal set for race id: #{race.id}, therefore we cannot create a fundraising team"
        }
      end

      it 'logs op-op and returns' do
        expect(worker).to receive(:log).with("no-op", log)
        worker.perform({'team_id' => team.id})
      end
    end

    context 'when user who owns the team cannot be linked to classy' do
      let(:race) { FactoryBot.create :race, :with_classy_data }
      let(:team) { FactoryBot.create :team, race: race }
      let(:ex)   { StandardError.new("omg") }

      it 'logs the error and re-raises' do
        expect(ClassyUser).to receive(:link_user_to_classy!).and_raise(ex)
        expect(worker).to receive(:log).with("error", {}, :error, ex)
        expect do
          worker.perform({'team_id' => team.id})
        end.to raise_error(ex)
      end
    end

    context 'when classy client errors' do
      let(:race) { FactoryBot.create :race, :with_classy_data }
      let(:team) { FactoryBot.create :team, race: race }
      let(:ex)   { StandardError.new("omg") }
      before do
        ENV['CLASSY_CLIENT_ID'] = 'some_id'
        ENV['CLASSY_CLIENT_SECRET'] = 'some_secret'
        stub_request(:post, ClassyClient::AUTH_ENDPOINT).to_return(status: 400)
      end

      it 'logs the error and re-raises' do
        expect(worker).to receive(:log).with("error", {}, :error, any_args)
        expect do
          worker.perform({'team_id' => team.id})
        end.to raise_error(TransientError)
      end
    end


    context 'when the fundraising team creation is successful' do
      let(:race) { FactoryBot.create :race, :with_classy_data }
      let(:team) { FactoryBot.create :team, race: race }
      let(:resp) { File.read("#{Rails.root}/spec/fixtures/classy/create_campaign_team_response.json") }
      let(:json) { JSON.parse(resp) }

      before do
        expect(ClassyClient).to receive(:new).and_return(valid_cc)
        expect(ClassyUser).to receive(:link_user_to_classy!).and_return(true)
        expect(valid_cc).to receive(:create_fundraising_team).and_return(json)
      end

      it 'saves the classy_id to the team, saves the team, logs complete, and enqueues Workers::ClassyFundraisingTeamEmail' do
        expect(worker).to receive(:log).with("complete", any_args)
        expect(Workers::ClassyFundraisingTeamEmail).to receive(:perform_async)
        worker.perform({'team_id' => team.id})
        expect(team.reload.classy_id).to eq(json['id'].to_s)
      end
    end
  end
end
