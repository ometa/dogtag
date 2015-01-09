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
      let(:endpoint) { lambda { get :edit, id: 1 }}
      include_examples 'redirects to login'
    end
    describe '#update' do
      let(:endpoint) { lambda { patch :update, id: 1 }}
      include_examples 'redirects to login'
    end
    describe '#show' do
      let(:endpoint) { lambda { get :show, id: 1 }}
      include_examples 'redirects to login'
    end
    describe '#destroy' do
      let(:endpoint) { lambda { delete :destroy, id: 1 }}
      include_examples 'redirects to login'
    end
  end

  context '[logged in]' do
    let (:valid_user) { FactoryGirl.create :admin_user }
    before do
      activate_authlogic
      mock_login! valid_user
    end

    describe '#new' do

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
        let(:race) { FactoryGirl.create :race }

        before do
          allow(Team).to receive(:new).and_return team
          get :new, :race_id => race.id
        end

        it 'returns http success' do
          expect(response).to be_success
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

      shared_examples 'is_http_success' do
        it 'returns success' do
          expect(response).to be_success
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
        let (:valid_team) { FactoryGirl.create :team }

        context '[no race_id]' do
          before { get :index }
          include_examples 'no_race'
          include_examples 'myteams_empty'
          include_examples 'is_http_success'
        end

        context '[valid race_id]' do
          before { get :index, :race_id => valid_team.race.id }

          it 'assigns @race' do
            expect(assigns(:race)).to eq(valid_team.race)
          end
          include_examples 'myteams_empty'
          include_examples 'is_http_success'
        end

        context '[unknown race_id]' do
          before { get :index, :race_id => 99 }
          it "does not assign @race" do
            expect(assigns(:race)).to be_nil
          end
          include_examples 'myteams_empty'
          include_examples 'is_http_success'
        end
      end

      context 'when user has teams' do
        let (:valid_team) { FactoryGirl.create :team, :user => valid_user }
        before do
          valid_team.user = valid_user
          valid_team.save
        end

        context '[no race_id]' do
          before { get :index }
          it "assigns @myteams to the user's teams" do
            expect(assigns(:myteams)).to eq([valid_team])
          end
          include_examples 'no_race'
          include_examples 'is_http_success'
        end

        context "[valid race_id]" do

          context "matching user's teams" do
            before do
              get :index, :race_id => valid_team.race.id
            end
            it 'sets race' do
              expect(assigns(:race)).to eq(valid_team.race)
            end
            it "assigns @myteams to the user's teams for this race" do
              expect(assigns :myteams).to eq([valid_team])
            end
            include_examples 'is_http_success'
          end

          context "not matching user's teams" do
            let(:team_different_race) { FactoryGirl.create :team }
            before do
              get :index, :race_id => team_different_race.race.id
            end
            it 'sets race' do
              expect(assigns(:race)).to eq(team_different_race.race)
            end
            include_examples 'myteams_empty'
            include_examples 'is_http_success'
          end
        end

        context '[unknown race_id]' do
          before { get :index, :race_id => 99 }
          include_examples 'no_race'
          it "assigns @myteams to the user's teams" do
            expect(assigns(:myteams)).to eq([valid_team])
          end
          include_examples 'is_http_success'
        end
      end
    end

    describe '#edit' do
      # edit is aliased to show, so no need to spec.
    end

    describe '#create' do
      let(:race) { FactoryGirl.create :race }
      let (:valid_team_hash) do
        _t = FactoryGirl.attributes_for :team
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
            post :create, :team => valid_team_hash
          end.to change(Team, :count).by 1
        end

        context 'upon success' do
          before do
            post :create, :team => valid_team_hash
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
          it 'redirects to team#show' do
            expect(response).to redirect_to(team_url(assigns(:team).id))
          end
        end
      end

      context 'with invalid team parameters' do
        before do
          team_stub = double('team', save: false).as_null_object
          allow(Team).to receive(:new).and_return team_stub
          post :create, :team => valid_team_hash
        end

        it 'returns http success' do
          expect(response).to be_success
        end
        it 'sets a flash notice' do
          expect(flash.now[:error]).to include(I18n.t 'create_failed')
          expect(flash.now[:error]).to_not be_nil
         end
      end
    end

    describe '#update' do
      let (:valid_team) { FactoryGirl.create :team }

      context 'on invalid id' do
        before { put :update, :id => 99 }
        it 'returns 404' do
          expect(response.status).to eq(404)
        end
      end

      context 'with valid patch data' do
        before do
          patch :update,
            :id => valid_team.id,
            :team => {:description => 'New Description'}
        end

        it 'updates the team' do
          expect(valid_team.reload.description).to eq('New Description')
        end
        it 'sets flash notice' do
          expect(flash[:notice]).to eq(I18n.t 'update_success')
        end
        it 'redirects to team#show' do
          expect(response).to redirect_to(team_url valid_team.id)
        end
      end
    end

    describe '#show' do
      context 'invalid id' do
        before { get :show, :id => 100 }

        it 'renders 404' do
          expect(response.status).to eq(404)
        end
      end

      context 'with valid id' do
        let (:valid_team) { FactoryGirl.create :team }
        before do
          get :show, :id => valid_team.id
        end

        it 'assigns team' do
          expect(assigns(:team)).to eq(valid_team)
        end
        it 'returns 200' do
          expect(response).to be_success
        end
        it 'assigns race' do
          expect(assigns(:race)).to eq(valid_team.race)
        end
      end

      context 'newly finalized (finalized? && ! notified_at)' do
        before do
          @now = Time.now
          Time.stub(:now) { @now }
          @team = FactoryGirl.create :team, :finalized, :user => valid_user
          get :show, :id => @team.id
        end

        it 'sets notified_at to Time.now and saves in db' do
          expect(Team.find(@team.id).notified_at).to eq(@now)
        end
        it 'the team thinks it is finalized' do
          expect(assigns(:team).finalized?).to be_true
        end
        it 'sets display_notification = true for the view'
        it 'emails the user'
        it 'logs'
      end

      context 'newly unfinalized (! finalized? && notified_at)' do
        before do
          @now = Time.now
          Time.stub(:now) { @now }
          @team = FactoryGirl.create :team
          @team.notified_at = @now - 1.month
          @team.save
          get :show, :id => @team.id
        end

        it 'the team thinks it is not finalized' do
          expect(assigns(:team).finalized?).to be_false
        end
        it 'unsets notified_at' do
          expect(assigns(:team).notified_at).to be_nil
        end
        it 'saves the database record' do
          expect(@team.reload.notified_at).to be_nil
        end
      end
    end

    describe '#destroy' do
      context 'on invalid id' do
        before { delete :destroy, :id => 99 }
        it 'returns 404' do
          expect(response.status).to eq(404)
        end
      end

      it 'destroys the team' do
        @team = FactoryGirl.create :team
        expect { delete :destroy, :id => @team.id }.to change(Team, :count).by(-1)
      end

      context 'with valid id' do
        let(:valid_team) { FactoryGirl.create :team }
        before do
          delete :destroy, :id => valid_team.id
        end

        it 'sets the flash notice' do
          expect(flash[:notice]).to eq(I18n.t 'delete_success')
        end
        it 'redirects to the team index' do
          expect(response).to redirect_to teams_path
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
