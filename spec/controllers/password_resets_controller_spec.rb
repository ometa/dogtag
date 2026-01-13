# Copyright (C) 2015 Devin Breen
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

describe PasswordResetsController do

  context '[logged out]' do

    shared_examples 'perishable token not found in db' do
      before do
        expect(User).to receive(:find_using_perishable_token).and_return(nil)
        endpoint.call
      end

      it 'sets flash error' do
        expect(flash[:error]).to eq("We're sorry, but we could not locate your account")
      end
      it 'redirects to home' do
        expect(response).to redirect_to(home_url)
      end
    end

    shared_examples 'assigns the user object' do
      it 'assigns the user object' do
        expect(assigns(:user)).to eq(user)
      end
    end

    describe '#new' do
      before do
        get :new
      end

      it 'renders 200' do
        expect(response).to be_successful
      end
      it 'renders #new' do
        expect(request).to render_template(:new)
      end
    end

    describe '#edit' do

      context 'when perishable_token does not find a user' do
        let(:endpoint) { lambda { get :edit, params: { id: '12345' } } }
        include_examples 'perishable token not found in db'
      end

      context 'when perishable_token is in db' do
        let(:user) { double('user').as_null_object }
        before do
          expect(User).to receive(:find_using_perishable_token).and_return(user)
          get :edit, params: { id: '12345' }
        end

        include_examples 'assigns the user object'

        it 'renders 200' do
          expect(response).to be_successful
        end
        it 'renders #edit' do
          expect(request).to render_template(:edit)
        end
      end
    end

    describe '#update' do

      context 'when perishable_token does not find a user' do
        let(:endpoint) { lambda { patch :update, params: { id: '12345' } } }
        include_examples 'perishable token not found in db'
      end

      context 'when perishable_token is in db' do
        before do
          expect(User).to receive(:find_using_perishable_token).and_return(user)
          endpoint.call
        end

        context 'when new password and confirmation are blank' do
          let(:user) { FactoryBot.create :user }
          let(:endpoint) { lambda { patch :update, params: { id: user.id, password: '', password_confirmation: '' } } }

          it 'sets flash error' do
            expect(flash[:error]).to eq('Ensure you supply a new password and confirmation')
          end
          it 'renders 200' do
            expect(response).to be_successful
          end
          it 'renders #edit' do
            expect(request).to render_template(:edit)
          end
          include_examples 'assigns the user object'
        end

        context 'when new password is accepted' do
          let(:user) { double('user', id: '12345', save: true).as_null_object }
          let(:endpoint) { lambda { patch :update, params: { id: user.id, password: 'foo', password_confirmation: 'foo' } } }

          it 'logs the user in automatically' do
            # Authlogic's save method (vs save_without_session_maintenance) automatically
            # creates a session. We verify this by checking that UserSession.create is called
            # or that save was called (not save_without_session_maintenance)
            expect(user).to have_received(:save)
          end

          it 'sets flash success' do
            expect(flash[:notice]).to eq("Your password was successfully updated")
          end
          it 'redirects to user page' do
            expect(response).to redirect_to(user_url(user.id))
          end
          include_examples 'assigns the user object'
        end

        context 'when new password is not accepted' do
          let(:errors) { double('errors', messages: 'foo') }
          let(:user) { double('user', id: '12345', save: false, errors: errors).as_null_object }
          let(:endpoint) { lambda { patch :update, params: { id: user.id, password: 'foo', password_confirmation: 'foo' } } }

          it 'sets flash error' do
            expect(flash[:error]).to eq('foo')
          end
          it 'renders 200' do
            expect(response).to be_successful
          end
          it 'renders #edit' do
            expect(request).to render_template(:edit)
          end
          include_examples 'assigns the user object'
        end
      end
    end

    describe '#create' do

      let(:user) { FactoryBot.create :user }

      context 'when user is not found' do

        it 'does not assign user, sets flash error, responds, 400, and renders #new' do
          expect(User).to receive(:find_by_email).and_return(nil)
          post :create, params: { email: user.email }
          expect(flash[:error]).to eq("No user was found with email address: #{user.email}")
          expect(assigns(:user)).to be_nil
          expect(response.code).to eq('400')
          expect(request).to render_template(:new)
        end
      end

      context 'when user is found' do

        it 'calls the reset operation, sets flash notice, and redirects to home' do
          expect(User).to receive(:find_by_email).with(user.email.downcase).and_return(user)
          expect(user).to receive(:reset_password!)
          post :create, params: { email: user.email }
          expect(flash[:notice]).to eq("Instructions to reset your password have been emailed to you")
          expect(response).to redirect_to(home_url)
        end

        it 'finds user with case-insensitive email lookup' do
          mixed_case_email = user.email.upcase
          expect(User).to receive(:find_by_email).with(mixed_case_email.downcase).and_return(user)
          expect(user).to receive(:reset_password!)
          post :create, params: { email: mixed_case_email }
          expect(flash[:notice]).to eq("Instructions to reset your password have been emailed to you")
          expect(response).to redirect_to(home_url)
        end
      end
    end
  end

  context '[logged in]' do
    before do
      @valid_user = FactoryBot.create :user
      activate_authlogic
      login_user! @valid_user
    end

    shared_examples 'logged in behavior' do
      it 'sets flash notice' do
        expect(flash[:notice]).to eq('You must be logged out to access this page')
      end
      it 'redirects to account_path' do
        expect(response).to redirect_to(account_url)
      end
    end

    describe '#update' do
      before { patch :update, params: { id: '12345' } }
      include_examples 'logged in behavior'
    end

    describe '#create' do
      before { post :create }
      include_examples 'logged in behavior'
    end

    describe '#edit' do
      before { get :edit, params: { id: '12345' } }
      include_examples 'logged in behavior'
    end

    describe '#new' do
      before { get :new }
      include_examples 'logged in behavior'
    end
  end
end
