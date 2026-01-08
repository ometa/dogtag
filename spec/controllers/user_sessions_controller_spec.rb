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

describe UserSessionsController do

  context '[logged out]' do
    describe '#destroy' do
      before do
        activate_authlogic
        delete :destroy
      end

      it 'redirects to login' do
        expect(response).to redirect_to(new_user_session_url)
      end

      it 'should not run the user_update_checker' do
        expect(controller.should_run_update_checker).to be_falsey
      end
    end

    describe '#new' do
      it 'returns http success' do
        activate_authlogic
        get :new
        expect(response).to be_successful
      end
    end

    describe '#create' do
      let(:user) { FactoryBot.create(:user) }
      let(:user_session_hash) do
        {
          email: user.email,
          password: user.password,
          remember_me: '1'
        }
      end

      context 'without user_session param' do
        it 'returns http 400' do
          post :create
          expect(response.status).to eq(400)
        end
      end

      context 'user_session saves successfully' do

        context 'with session[:return_to]' do
          before do
            session[:return_to] = home_url
            post :create, params: { user_session: user_session_hash }
          end

          it 'sets flash and redirects to session[:return_to]' do
            expect(flash[:notice]).to eq(I18n.t 'login_success')
            expect(response).to redirect_to(home_url)
          end
        end

        context 'without session[:return_to]' do
          before do
            post :create, params: { user_session: user_session_hash }
          end

          it 'sets flash and redirects to account page' do
            expect(flash[:notice]).to eq(I18n.t 'login_success')
            expect(response).to redirect_to(account_url)
          end
        end
      end

      context 'on failure to save the user_session' do
        let(:user_session_hash) do
          {
            email: user.email,
            password: 'incorrect',
            remember_me: '1'
          }
        end
        before do
          post :create, params: { :user_session => user_session_hash }
        end

        it 'sets a flash notice' do
          expect(flash[:error]).to eq(I18n.t 'login_failed')
        end

        it 'renders user_session#new' do
          expect(response.status).to eq(200)
          expect(response).to render_template(:new)
        end
      end
    end
  end

  context '[logged in]' do
    let(:user) { FactoryBot.create :user }
    before do
      activate_authlogic
      login_user! user
    end

    describe '#destroy' do
      before do
        delete :destroy
      end

      it 'sets flash notice and redirects to home' do
        expect(flash[:notice]).to eq(I18n.t 'logout_success')
        expect(response).to redirect_to(home_url)
      end
    end
  end
end
