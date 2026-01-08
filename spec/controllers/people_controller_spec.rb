# Copyright (C) 2014 Devin Breen
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

describe PeopleController do

  context '[logged out]' do
    describe '#new' do
      it 'redirects to login' do
        get :new, params: { :team_id => -1 }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    describe '#create' do
      it 'redirects to login' do
        post :create, params: { :team_id => -1 }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    describe '#edit' do
      it 'redirects to login' do
        get :edit, params: { :team_id => -1, :id => 1 }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    describe '#update' do
      it 'redirects to login' do
        patch :update, params: { :team_id => -1, :id => 1 }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    describe '#destroy' do
      it 'redirects to login' do
        delete :destroy, params: { :team_id => -1, :id => 1 }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  context '[logged in]' do
    let(:team)   { FactoryBot.create :team, :with_people }
    let(:person) { team.people.first }

    before do
      @valid_user = FactoryBot.create :admin_user
      activate_authlogic
      login_user! @valid_user
    end

    describe '#destroy' do
      context 'on invalid id' do
        before { delete :destroy, params: { :team_id => team.id, :id => 99 } }

        it 'returns 404' do
          expect(response.status).to eq(404)
        end
      end

      it 'destroys a record correctly' do
        team = FactoryBot.create :team, :with_people
        expect do
          delete :destroy, params: { :team_id => team.id, :id => team.people.first.id }
        end.to change(Person, :count).by(-1)
      end

      it 'broadcasts when destroying the record' do
        expect do
          delete :destroy, params: { :team_id => team.id, :id => team.people.first.id }
        end.to broadcast(:destroy_person_successful)
      end

      # we don't want to remove a person record once we reach the correct number, as
      # it would cause the team to no longer be complete
      context 'when team requirements are all met' do
        it 'does not destroy the record'
      end

      context 'with valid id' do
        before do
          delete :destroy, params: { :team_id => team.id, :id => person.id }
        end

        it 'sets flash notice and redirects to team#show' do
          expect(flash[:notice]).to eq(I18n.t 'delete_success')
          expect(response).to redirect_to(team_url :id => team.id)
        end
      end

      context "if destroy fails" do
        before do
          expect_any_instance_of(Person).to receive(:destroy).and_return(false)
          delete :destroy, params: { :team_id => team.id, :id => person.id }
        end

        it "sets flash" do
          expect(flash[:error]).to eq(I18n.t('destroy_failed'))
        end
      end
    end

    describe '#update' do
      context 'on invalid id' do
        before { put :update, params: { :team_id => team.id, :id => 99 } }
        it 'returns 404' do
          expect(response.status).to eq(404)
        end
      end

      context 'with valid patch data' do
        before do
          patch :update, params: { :id => person.id, :team_id => team.id, :person => {:last_name => 'foo'} }
        end
        it 'updates the user, sets team (needed by _form.html.haml), sets flash, and redirects to team#show' do
          expect(person.reload.last_name).to eq('foo')
          expect(assigns(:team)).to eq(team)
          expect(flash[:notice]).to eq(I18n.t 'update_success')
          expect(response).to redirect_to(team_url :id => team.id)
        end
      end

      context "if update fails" do
        before do
          # Rails 6.1+: update_attributes was removed, use update instead
          expect_any_instance_of(Person).to receive(:update).and_return(false)
          patch :update, params: { :id => person.id, :team_id => team.id, :person => {:last_name => 'foo'} }
        end

        it "sets flash" do
          result = [I18n.t('update_failed'), {}]
          expect(flash.now[:error]).to match_array(result)
        end
      end
    end

    describe '#edit' do
      context 'with invalid user id' do
        before do
          get :edit, params: { :team_id => team.id, :id => -1 }
        end
        it 'responds with 404' do
          expect(response.status).to eq(404)
        end
      end

      context 'with valid user id' do
        before do
          get :edit, params: { :team_id => team.id, :id => person.id }
        end
        it 'assigns person and returns 200' do
          expect(assigns(:person)).to eq(person)
          expect(response).to be_successful
        end
      end
    end

    describe '#new' do
      let(:dude) { Person.new }
      before do
        allow(Person).to receive(:new).and_return(dude)
        get :new, params: { :team_id => team.id }
      end

      it 'assigns person to Person.new, sets team (needed by _form.html.haml), and returns http success' do
        expect(assigns(:person)).to eq(dude)
        expect(assigns(:team)).to eq(team)
        expect(response).to be_successful
      end
    end

    describe '#create' do
      let (:team_no_people) { FactoryBot.create :team }
      let (:new_person_hash) { FactoryBot.attributes_for :person, :first_name => 'Dan', :last_name => 'Akroyd' }

      context 'without person param' do
        it 'returns 400' do
          post :create, params: { :team_id => team_no_people.id }
          expect(response.status).to eq(400)
        end
      end

      it 'adds a record' do
        expect do
          post :create, params: { :team_id => team_no_people.id, :person => new_person_hash }
        end.to change(Person, :count).by 1
      end

      it 'broadcasts when creating the record' do
        expect do
          post :create, params: { :team_id => team_no_people.id, :person => new_person_hash }
        end.to broadcast(:create_person_successful)
      end

      context 'upon success' do
        before do
          post :create, params: { :team_id => team_no_people.id, :person => new_person_hash }
        end

        it 'assigns person to team, sets a flash notice, redirects to team#show' do
          expect(assigns(:person).team).to eq(team_no_people)
          expect(flash[:notice]).to eq(I18n.t 'create_success')
          expect(response).to redirect_to team_url(team_no_people.id)
        end
      end

      context "when person object is invalid" do

        let(:incomplete_hash) { new_person_hash.delete(:email); new_person_hash }

        it 'returns http success and sets flash error' do
          post :create, params: { :team_id => team.id, :person => incomplete_hash }
          expect(response).to be_successful
          expect(flash[:error]).to_not be_nil
        end
      end
    end
  end
end
