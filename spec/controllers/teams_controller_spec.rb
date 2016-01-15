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
    # todo: change unprivileged calls to use normal_user instead of admin_user
    let (:valid_user)     { FactoryGirl.create :admin_user }
    let (:admin_user)     { FactoryGirl.create :admin_user }
    let (:operator_user)  { FactoryGirl.create :admin_user }
    let (:normal_user)    { FactoryGirl.create :user } # unused for now ^^

    before do
      activate_authlogic
      mock_login! the_user
    end

    describe '#new' do
      let(:the_user) { valid_user }

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
      let(:the_user) { valid_user }

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
          it 'sorts newest to oldest'
          include_examples 'no_race'
          include_examples 'is_http_success'
        end

        context "[valid race_id]" do

          context "matching user's teams" do
            before do
              get :index, :race_id => valid_team.race.id
            end
            it "sets race and assigns @myteams to the user's teams for this race" do
              expect(assigns(:race)).to eq(valid_team.race)
              expect(assigns :myteams).to eq([valid_team])
            end
            it 'sorts newest to oldest'
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

      let(:race) { FactoryGirl.create :race }
      let(:valid_team_hash) do
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
          it 'redirects to team#questions' do
            expect(response).to redirect_to(team_questions_url(assigns(:team).id))
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
      let(:the_user) { valid_user }
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
        it 'redirects to team#questions' do
          expect(response).to redirect_to(team_questions_url valid_team.id)
        end
      end
    end

    describe '#show' do
      context 'invalid id' do
        let(:the_user) { valid_user }
        before { get :show, :id => 100 }

        it 'renders 404' do
          expect(response.status).to eq(404)
        end
      end

      context 'with valid id' do
        let(:the_user) { valid_user }
        let(:valid_team) { FactoryGirl.create :team }
        before do
          get :show, :id => valid_team.id
        end

        it 'assigns team, assigns race, returns 200' do
          expect(assigns(:team)).to eq(valid_team)
          expect(assigns(:race)).to eq(valid_team.race)
          expect(response).to be_success
        end
      end

      shared_examples "finalizes" do
        it "calls team.finalize and displays a message to user" do
          allow(Team).to receive(:find).and_return(team)
          expect(team).to receive(:finalize).and_return(true)
          get :show, id: team.id
          expect(assigns(:display_notification)).to eq(:notify_now_complete)
        end
      end

      context 'team is ready for finalization' do
        let(:team) { FactoryGirl.create :team, :with_people, people_count: 3 }

        context "admin user" do
          let(:the_user) { admin_user }
          include_examples "finalizes"
        end

        context "operator user" do
          let(:the_user) { operator_user }
          include_examples "finalizes"
        end

        context "when web user is the team's user" do
          let(:the_user) { team.user }
          include_examples "finalizes"
        end
      end

      context 'newly unfinalized (!meets_finalization_requirements? && finalized)' do
        let(:team) { FactoryGirl.create :team, :with_people, finalized: true }
        let(:the_user) { team.user }

        it 'calls team.unfinalize' do
          allow(Team).to receive(:find).and_return(team)
          expect(team).to receive(:unfinalize)
          get :show, :id => team.id
        end
      end
    end

    describe '#destroy' do

      let(:the_user) { valid_user }

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
