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

describe TeamsController do

  context '[logged out]' do
    shared_examples 'redirects to login' do
      it 'redirects to login' do
        endpoint.call
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe '#index' do
      let(:endpoint) { lambda { get :index }}
      include_examples 'redirects to login'
    end
    describe '#new' do
      let(:endpoint) { lambda { get :new }}
      include_examples 'redirects to login'
    end
    describe '#create' do
      let(:endpoint) { lambda { post :create }}
      include_examples 'redirects to login'
    end
    describe '#edit' do
      let(:endpoint) { lambda { get :edit, params: { id: 1 } }}
      include_examples 'redirects to login'
    end
    describe '#update' do
      let(:endpoint) { lambda { patch :update, params: { id: 1 } }}
      include_examples 'redirects to login'
    end
    describe '#show' do
      let(:endpoint) { lambda { get :show, params: { id: 1 } }}
      include_examples 'redirects to login'
    end
    describe '#destroy' do
      let(:endpoint) { lambda { delete :destroy, params: { id: 1 } }}
      include_examples 'redirects to login'
    end
  end

  context '[logged in]' do
    # todo: change unprivileged calls to use normal_user instead of admin_user
    let (:valid_user)     { FactoryBot.create :admin_user }
    let (:admin_user)     { FactoryBot.create :admin_user }
    let (:operator_user)  { FactoryBot.create :admin_user }
    let (:normal_user)    { FactoryBot.create :user } # unused for now ^^

    before do
      activate_authlogic
      login_user! the_user
    end

    describe '#new' do
      let!(:the_user) { valid_user }

      context 'without :race_id param' do
        before { get :new }

        it 'sets flash error' do
          expect(flash[:error]).to eq(I18n.t 'must_select_race')
        end
        it 'redirects to races index' do
          expect(response).to redirect_to(races_path)
        end
      end

      context 'with :race_id param' do
        let(:team) { Team.new }
        let(:race) { FactoryBot.create :race }

        before do
          allow(Team).to receive(:new).and_return team
          get :new, params: { :race_id => race.id }
        end

        it 'returns http success' do
          expect(response).to be_successful
        end
        it 'assigns team to Team.new' do
          expect(assigns(:team)).to eq(team)
        end
        it 'assigns race' do
          expect(assigns(:race)).to eq(race)
        end
        it 'assigns the race to the team' do
          expect(assigns(:team).race).to eq(race)
        end
      end

      context 'with invalid :race_id param'
    end

    describe '#index' do
      let(:the_user) { valid_user }

      shared_examples 'is_http_success' do
        it 'returns success' do
          expect(response).to be_successful
        end
      end
      shared_examples 'myteams_empty' do
        it 'sets @myteams to empty array' do
          expect(assigns(:myteams)).to be_empty
        end
      end
      shared_examples 'no_race' do
        it "does not assign @race" do
          expect(assigns(:race)).to be_nil
        end
      end

      context 'when user has no teams' do
        let (:valid_team) { FactoryBot.create :team }

        context '[no race_id]' do
          before { get :index }
          include_examples 'no_race'
          include_examples 'myteams_empty'
          include_examples 'is_http_success'
        end

        context '[valid race_id]' do
          before { get :index, params: { :race_id => valid_team.race.id } }

          it 'assigns @race' do
            expect(assigns(:race)).to eq(valid_team.race)
          end
          include_examples 'myteams_empty'
          include_examples 'is_http_success'
        end

        context '[unknown race_id]' do
          before { get :index, params: { :race_id => -1 } }
          it "does not assign @race" do
            expect(assigns(:race)).to be_nil
          end
          include_examples 'myteams_empty'
          include_examples 'is_http_success'
        end
      end

      context 'when user has teams' do
        let (:valid_team) { FactoryBot.create :team, :user => valid_user }
        before do
          valid_team.user = valid_user
          valid_team.save
        end

        context '[no race_id]' do
          before { get :index }
          it "assigns @myteams to the user's teams" do
            expect(assigns(:myteams)).to eq([valid_team])
          end
          it 'sorts newest to oldest'
          include_examples 'no_race'
          include_examples 'is_http_success'
        end

        context "[valid race_id]" do

          context "matching user's teams" do
            before do
              get :index, params: { :race_id => valid_team.race.id }
            end
            it "sets race and assigns @myteams to the user's teams for this race" do
              expect(assigns(:race)).to eq(valid_team.race)
              expect(assigns :myteams).to eq([valid_team])
            end
            it 'sorts newest to oldest'
            include_examples 'is_http_success'
          end

          context "not matching user's teams" do
            let(:team_different_race) { FactoryBot.create :team }
            before do
              get :index, params: { :race_id => team_different_race.race.id }
            end
            it 'sets race' do
              expect(assigns(:race)).to eq(team_different_race.race)
            end
            include_examples 'myteams_empty'
            include_examples 'is_http_success'
          end
        end

        context '[unknown race_id]' do
          before { get :index, params: { :race_id => -1 } }
          include_examples 'no_race'
          it "assigns @myteams to the user's teams" do
            expect(assigns(:myteams)).to eq([valid_team])
          end
          include_examples 'is_http_success'
        end
      end
    end

    describe '#jsonform' do
      let(:the_user) { valid_user }

      context 'when team_id is not found in db' do
        it 'sets flash error'
        it 'redirects to home page'
      end
    end

    describe '#edit' do
      # edit is aliased to show, so no need to spec.
    end

    describe '#create' do
      let(:the_user) { valid_user }

      let(:race) { FactoryBot.create :race }
      let(:valid_team_hash) do
        _t = FactoryBot.attributes_for :team
        _t.merge(:race_id => race.id)
      end

      context 'without team param' do
        it 'returns 400' do
          post :create
          expect(response.status).to eq(400)
        end
      end

      context 'with valid team parameters' do
        it 'writes a new db record' do
          expect do
            post :create, params: { :team => valid_team_hash }
          end.to change(Team, :count).by 1
        end

        it 'broadcasts when creating the record' do
          expect do
            post :create, params: { :team => valid_team_hash }
          end.to broadcast(:create_team_successful)
        end

        context 'upon success' do
          before do
            post :create, params: { :team => valid_team_hash }
          end

          it 'associates the current user with the new team' do
            expect(assigns(:team).user).to eq(valid_user)
          end
          it 'assigns team' do
            expect(assigns(:team)).to be_present
          end
          it 'sets a flash notice' do
            expect(flash[:notice]).to eq(I18n.t 'create_success')
          end
          it 'redirects to team#questions' do
            expect(response).to redirect_to(team_questions_url(assigns(:team).id))
          end
        end
      end

      context 'with invalid team parameters' do
        before do
          team_stub = double('team', save: false).as_null_object
          allow(Team).to receive(:new).and_return team_stub
          post :create, params: { :team => valid_team_hash }
        end

        it 'returns http success' do
          expect(response).to be_successful
        end
        it 'sets a flash notice' do
          expect(flash.now[:error]).to include(I18n.t 'create_failed')
          expect(flash.now[:error]).to_not be_nil
         end
      end
    end

    describe '#update' do
      let(:the_user) { valid_user }

      context 'on invalid id' do
        before { put :update, params: { :id => -1 } }
        it 'returns 404' do
          expect(response.status).to eq(404)
        end
      end

      context 'when validation fails on update'

      context 'with valid patch data' do
        let(:team) { FactoryBot.create :team }

        before do
          patch :update, params: { :id => team.id, :team => {:description => 'New Description'} }
        end

        it 'updates the team' do
          expect(team.reload.description).to eq('New Description')
        end

        context 'team has answered questions already' do
          let(:team) { FactoryBot.create :team_with_jsonform }

          it 'sets flash notice and redirects to team#show' do
            expect(response).to redirect_to(team_url(team.id))
            expect(flash[:notice]).to eq(I18n.t 'update_success')
          end
        end

        context 'team has not answered questions and questions exist' do
          let(:race) { FactoryBot.create :race_with_jsonform }
          let(:team) { FactoryBot.create :team, race: race }

          it 'sets flash notice and redirects to team#questions' do
            expect(response).to redirect_to(team_questions_url(team.id))
            expect(flash[:notice]).to eq(I18n.t 'teams.update.success_fill_out_questions')
          end
        end

        it 'broadcasts when updating the record' do
          expect do
            patch :update, params: { :id => team.id, :team => {:description => 'New Description'} }
          end.to broadcast(:update_team_successful)
        end
      end
    end

    describe '#show' do
      let(:the_user) { valid_user }

      context 'using invalid team id' do
        before { get :show, params: { :id => 100 } }

        it 'renders 404' do
          expect(response.status).to eq(404)
        end
      end

      context 'using valid team id' do
        let(:team) { FactoryBot.create :team }

        it 'assigns team, assigns race, returns 200' do
          get :show, params: { :id => team.id }
          expect(assigns(:team)).to eq(team)
          expect(assigns(:race)).to eq(team.race)
          expect(response).to be_successful
        end

        it 'does not cache this page' do
          get :show, params: { :id => team.id }
          # Rails 7.0: Cache-Control header changed from 'no-cache, no-store' to 'no-store'
          expect(response.headers['Cache-Control']).to eq('no-store')
          expect(response.headers['Pragma']).to eq('no-cache')
        end

        context "if the team is finalized" do
          let(:team) { FactoryBot.create :finalized_team }

          it "does not display finalization banner since user is not the team captain" do
            get :show, params: { :id => team.id }
            expect(assigns(:display_notification)).to be_nil
          end

          context "and is being viewed by the team captain" do
            let(:the_user) { team.user }

            it "displays a banner on the page" do
              get :show, params: { :id => team.id }
              expect(assigns(:display_notification)).to eq(:notify_now_complete)
            end
          end
        end
      end
    end

    describe '#destroy' do
      let(:the_user) { valid_user }

      context 'on invalid id' do
        before { delete :destroy, params: { :id => -1 } }
        it 'returns 404' do
          expect(response.status).to eq(404)
        end
      end

      it 'destroys the record' do
        team = FactoryBot.create :team
        expect do
          delete :destroy, params: { :id => team.id }
        end.to change(Team, :count).by(-1)
      end

      it 'broadcasts when destroying the record' do
        team = FactoryBot.create :team
        expect do
          delete :destroy, params: { :id => team.id }
        end.to broadcast(:destroy_team_successful)
      end

      context 'with valid id' do
        let(:valid_team) { FactoryBot.create :team }
        before do
          delete :destroy, params: { :id => valid_team.id }
        end

        it 'sets the flash notice and redirects to the team index' do
          expect(flash[:notice]).to eq(I18n.t 'delete_success')
          expect(response).to redirect_to(teams_path)
        end
      end

      context 'when team has made payments' do
        it 'does not allow deletion'
        it 'sets the flash notice'
        it 'redirects to the team index'
      end
    end
  end
end
