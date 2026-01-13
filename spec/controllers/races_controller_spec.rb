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
require 'spec_helper'

describe RacesController do

  context '[logged out]' do
    describe '#new' do
      it 'redirects to login' do
        get :new; expect(response).to redirect_to(new_user_session_path)
      end
    end
    describe '#create' do
      it 'redirects to login' do
        post :create; expect(response).to redirect_to(new_user_session_path)
      end
    end
    describe '#edit' do
      it 'redirects to login' do
        get :edit, params: { :id => 1 }; expect(response).to redirect_to(new_user_session_path)
      end
    end
    describe '#update' do
      it 'redirects to login' do
        patch :update, params: { :id => 1 }; expect(response).to redirect_to(new_user_session_path)
      end
    end
    describe '#destroy' do
      it 'redirects to login' do
        delete :destroy, params: { :id => 1 }; expect(response).to redirect_to(new_user_session_path)
      end
    end
    describe '#export' do
      it 'redirects to login' do
        get :export, params: { :race_id => 1 }; expect(response).to redirect_to(new_user_session_path)
      end
    end
    describe '#registrations' do
      it 'redirects to login' do
        get :registrations, params: { :race_id => 1 }; expect(response).to redirect_to(new_user_session_path)
      end
    end
    describe '#show'
  end

  context '[logged in]' do
    before do
      activate_authlogic
      user = FactoryBot.create :admin_user
      login_user! user
    end

    describe '#registrations' do

      shared_examples "empty_finalized_teams" do
        it "assigns finalized_teams to []" do
          expect(assigns :finalized_teams).to be_empty
        end
      end
      shared_examples "empty_waitlisted_teams" do
        it "assigns waitlisted_teams to []" do
          expect(assigns :waitlisted_teams).to be_empty
        end
      end

      context 'with invalid race_id' do
        before { get :registrations, params: { :race_id => 100 } }
        it 'sets 404' do
          expect(response.status).to eq(404)
        end
      end

      context "with no teams" do
        let(:race) { FactoryBot.create :race }
        before { get :registrations, params: { :race_id => race.id } }

        include_examples 'empty_finalized_teams'
        include_examples 'empty_waitlisted_teams'
      end

      context "with a finalized team" do
        let(:team) { FactoryBot.create :finalized_team }
        before { get :registrations, params: { :race_id => team.race.id } }

        it 'assigns finalized_teams' do
          expect(assigns :finalized_teams).to eq([team])
        end
        include_examples 'empty_waitlisted_teams'
      end

      context "with a non-finalized team" do
        let(:team) { FactoryBot.create :team }
        before { get :registrations, params: { :race_id => team.race.id } }

        it 'assigns waitlisted_teams' do
          expect(assigns :waitlisted_teams).to eq([team])
        end
        include_examples 'empty_finalized_teams'
      end
    end

    describe '#export' do
      context 'with invalid id' do
        before { get :export, params: { :race_id => 100 } }

        it 'sets 404' do
          expect(response.status).to eq(404)
        end
      end

      context 'with valid id' do
        let(:team) { FactoryBot.create :finalized_team }

        it 'returns 200' do
          get :export, params: { :race_id => team.race.id }
          expect(response).to be_successful
        end

        it 'sends CSV data' do
          get :export, params: { :race_id => team.race.id }
          expect(response.content_type).to include('text/csv')
        end

        it 'sets headers correctly' do
          get :export, params: { :race_id => team.race.id }
          expect(response.headers['Content-Disposition']).to include("attachment")
          expect(response.headers['Content-Disposition']).to include("race_#{team.race.id}_export.csv")
        end

        it 'sends finalized and non-finalized registrations by default' do
          unfinalized_team = FactoryBot.create :team, race: team.race
          get :export, params: { :race_id => team.race.id }
          expect(response.body).to include(team.name)
          expect(response.body).to include(unfinalized_team.name)
        end

        it 'sends only finalized data when params[:finalized] is present' do
          unfinalized_team = FactoryBot.create :team, race: team.race
          get :export, params: { :race_id => team.race.id, :finalized => true }
          expect(response.body).to include(team.name)
          expect(response.body).not_to include(unfinalized_team.name)
        end
      end
    end

    describe '#show' do
      context 'with invalid id' do
        before { get :show, params: { :id => 100 } }
        it 'sets 404' do
          expect(response.status).to eq(404)
        end
      end

      context 'with valid id' do
        before do
          @race = FactoryBot.create :race
          get :show, params: { :id => @race.id }
        end

        it 'sets the @race object' do
          expect(assigns(:race)).to eq(@race)
        end

        it 'returns 200' do
          expect(response).to be_successful
        end

        it "sets @my_race_teams to the user's teams for this race" do
          user = controller.send(:current_user)
          team = FactoryBot.create :team, race: @race, user: user
          FactoryBot.create :team, race: @race
          get :show, params: { :id => @race.id }
          expect(assigns(:my_race_teams)).to eq([team])
        end
      end
    end

    describe '#edit' do
      # edit is aliased to show, so no need to spec.
    end

    describe '#update' do
      context 'with invalid id' do
        before { put :update, params: { :id => 99 } }
        it 'returns 404' do
          expect(response.status).to eq(404)
        end
      end

      context 'with valid patch data' do
        let(:race) { FactoryBot.create :race }
        before do
          patch :update, params: { :id => race.id, :race => {:max_teams => 200} }
        end
        it 'updates the race, sets flash, redirects to race#edit' do
          expect(race.reload.max_teams).to eq(200)
          expect(flash[:notice]).to eq(I18n.t 'update_success')
          expect(response).to redirect_to(edit_race_url race.id)
        end

        it 'converts filter_field array into comma-separated list' do
          race = FactoryBot.create :race
          patch :update, params: { :id => race.id, :race => { :filter_field => ['field1', 'field2', 'field3'] } }
          expect(race.reload.filter_field).to eq('field1,field2,field3')
        end
      end
    end

    describe '#create' do
      let (:valid_race_hash) { FactoryBot.attributes_for :race }

      it 'returns 400 if the race parameter is not passed' do
        post :create
        expect(response.status).to eq(400)
      end

      it 'returns 200 and sets flash[:error] when required params are missing' do
        required = [:name, :race_datetime, :max_teams, :people_per_team, :registration_open, :registration_close]
        required.each do |param|
          bad_payload = valid_race_hash.dup
          bad_payload.delete param
          post :create, params: { :race => bad_payload }
          expect(response.status).to eq(200)
          expect(flash[:error]).not_to be_nil
          expect(flash[:error].detect { |val| val.is_a? Hash }).to include param
        end
      end

      it 'adds a record' do
        expect do
          post :create, params: { :race => valid_race_hash }
        end.to change(Race, :count).by 1
      end

      context 'upon success' do
        before do
          post :create, params: { :race => valid_race_hash }
        end

        it 'converts filter_field array into comma-separated list' do
          hash = FactoryBot.attributes_for(:race).merge(:filter_field => ['fieldA', 'fieldB'])
          expect {
            post :create, params: { :race => hash }
          }.to change(Race, :count).by(1)
          expect(Race.order(:created_at).last.filter_field).to eq('fieldA,fieldB')
        end

        it 'sets a flash notice' do
          expect(flash[:notice]).to eq(I18n.t 'create_success')
        end

        it 'redirects to races index' do
          expect(response).to redirect_to races_path
        end
      end
    end

    describe '#index' do
      it 'returns http success, sets @races to all races' do
        race1 = FactoryBot.create :race
        race2 = FactoryBot.create :race
        get :index
        expect(response).to be_successful
        expect(assigns(:races)).to eq([race1, race2])
      end
    end

    describe '#new' do
      let(:race) { double "race" }
      before do
        allow(Race).to receive(:new).and_return(race)
        get :new
      end

      it 'returns http success, assigns @race to Race.new' do
        expect(response).to be_successful
        expect(assigns(:race)).to eq(race)
      end
    end

    describe '#destroy' do
      context 'on invalid id' do
        before { delete :destroy, params: { :id => 99 } }
        it 'returns 404' do
          expect(response.status).to eq(404)
        end
      end

      context 'on valid id' do
        before do
          @race = FactoryBot.create :race
        end

        it 'destroys the race' do
          expect { delete :destroy, params: { :id => @race.id } }.to change(Race, :count).by(-1)
        end

        context 'with valid id' do
          before do
            delete :destroy, params: { :id => @race.id }
          end

          it 'sets the flash notice' do
            expect(flash[:notice]).to eq(I18n.t 'delete_success')
          end
          it 'redirects to the user index' do
            expect(response).to redirect_to races_path
          end
        end
      end
    end
  end
end
