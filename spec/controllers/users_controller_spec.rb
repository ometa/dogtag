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

describe UsersController do

  context '[logged out]' do

    describe '#index' do
      it 'redirects to login' do
        get :index; expect(response).to redirect_to(new_user_session_path)
      end
    end
    describe '#show' do
      it 'redirects to login' do
        get :show; expect(response).to redirect_to(new_user_session_path)
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

    describe '#new' do
      before do
        @user_stub = User.new
        allow(User).to receive(:new).and_return @user_stub
        get :new
      end

      it 'returns http success' do
        expect(response).to be_successful
      end
      it 'assigns @user to User.new' do
        expect(assigns(:user)).to eq(@user_stub)
      end
    end

    describe '#create' do
      let(:valid_user_hash) { FactoryBot.attributes_for :user }

      it 'returns 400 if the user parameter is not passed' do
        post :create
        expect(response.status).to eq(400)
      end

      %i(first_name last_name email phone password password_confirmation).each do |param|

        context "when required param '#{param}' is missing" do

          it 'returns 200 and sets flash[:error]' do
            bad_payload = valid_user_hash.dup
            bad_payload.delete param
            post :create, params: { :user => bad_payload }
            expect(response.status).to eq(200)
            expect(flash[:error].detect { |val| val.is_a? Hash }).to include param
          end
        end
      end

      it 'adds a record' do
        expect do
          post :create, params: { :user => valid_user_hash }
        end.to change(User, :count).by(1)
      end

      context 'when user save is successful' do
        it 'sends a welcome email, sets a flash notice, and redirects to user#show' do
          expect(Workers::WelcomeEmail).to receive(:perform_async)
          post :create, params: { :user => valid_user_hash }
          expect(flash[:notice]).to eq(I18n.t 'create_success_user')
          expect(response).to redirect_to assigns(:user)
        end
      end
    end
  end

  context '[logged in]' do
    let(:valid_user) { FactoryBot.create :admin_user }
    let(:some_user)  { FactoryBot.create :user }
    let(:new_user)   { User.new }

    before do
      activate_authlogic
      login_user! valid_user
    end

    describe '#new' do
      before do
        allow(User).to receive(:new).and_return(new_user)
        get :new
      end

      it 'assigns @user to User.new and returns success' do
        expect(assigns(:user)).to eq(new_user)
        expect(response).to be_successful
      end
    end

    describe '#index' do

      it 'sets @users to all users and returns http success' do
        get :index
        expect(assigns(:users)).to_not be_nil
        expect(response).to be_successful
      end
    end

    describe '#show' do

      context 'with invalid user id' do

        it 'runs the user_update_checker and returns 404' do
          get :show, params: { :id => -1 }
          expect(controller.should_run_update_checker).to be true
          expect(response.status).to eq(404)
        end
      end

      context 'with valid user id' do

        it 'sets the @user, runs the user_update_checker, returns 200' do
          get :show, params: { :id => some_user.id }
          expect(assigns(:user)).to eq(some_user)
          expect(controller.should_run_update_checker).to be true
          expect(response).to be_successful
        end
      end
    end

    describe '#edit' do

      context 'with invalid user id' do

        it 'does not run user_update_checker and returns 404' do
          get :edit, params: { :id => -1 }
          expect(controller.should_run_update_checker).to be false
          expect(response.status).to eq(404)
        end
      end

      context 'with valid user id' do

        it 'sets the @user object, returns 200, does not run user_update_checker' do
          get :edit, params: { :id => some_user.id }
          expect(assigns(:user)).to eq(some_user)
          expect(response).to be_successful
          expect(controller.should_run_update_checker).to be false
        end
      end
    end

    describe '#update' do

      context 'on invalid id' do

        it 'does not run user_update_checker and returns 404' do
          put :update, params: { :id => -1 }
          expect(controller.should_run_update_checker).to be false
          expect(response.status).to eq(404)
        end
      end

      context 'with valid patch data' do

        it 'updates the user, does not run user_update_checker, sets flash, and redirects to user#show' do
          patch :update, params: { :id => some_user.id, :user => {:phone => '000-000-0000'} }
          expect(some_user.reload.phone).to eq('000-000-0000')
          expect(controller.should_run_update_checker).to be false
          expect(flash[:notice]).to eq(I18n.t 'users.update.update_success')
          expect(response).to redirect_to(some_user)
        end
      end
    end

    describe '#destroy' do

      context 'on invalid id' do

        it 'returns 404' do
          delete :destroy, params: { :id => -1 }
          expect(response.status).to eq(404)
        end
      end

      #todo - there's probably a way to DRY this up.
      context 'with valid id' do

        it 'destroys the user' do
          some_user = FactoryBot.create :user
          expect do
            delete :destroy, params: { :id => some_user.id }
          end.to change(User, :count).by(-1)
        end

        it 'sets the flash notice and redirects to the user index' do
          delete :destroy, params: { :id => some_user.id }
          expect(flash[:notice]).to eq(I18n.t 'delete_success')
          expect(response).to redirect_to users_path
        end
      end

      it 'sets flash error and redirects if delete fails' do
        user = FactoryBot.create :user
        allow_any_instance_of(User).to receive(:destroy).and_return(false)
        delete :destroy, params: { :id => user.id }
        expect(flash[:error]).to eq(I18n.t 'destroy_failed')
        expect(response).to redirect_to users_path
      end
    end
  end
end
