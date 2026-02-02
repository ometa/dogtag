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
require 'stripe_mock'

describe ChargesController do

  let(:stripe_helper) { StripeMock.create_test_helper }

  context '[logged out]' do
    shared_examples 'redirects to login' do
      it 'redirects to login' do
        endpoint.call
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe '#create' do
      let(:endpoint) { lambda { post :create }}
      include_examples 'redirects to login'
    end
    describe '#refund' do
      let(:endpoint) { lambda { post :refund, params: { charge_id: 1 } }}
      include_examples 'redirects to login'
    end
  end

  context '[logged in]' do

    shared_examples "redirects to prior url" do
      it 'redirects to the prior url' do
        expect(response).to redirect_to('/prior_url/')
      end
    end

    let(:valid_user) { FactoryBot.create :user }
    let(:the_user)   { valid_user }
    before do
      activate_authlogic
      login_user! the_user
    end

    describe '#create' do

      context 'when session[:prior_url] is not set' do
        let(:error_json) {{ errors: "The calling controller should set session[:prior_url] so this method knows where to return to. e.g. session[:prior_url] = request.original_url"}.to_json}
        it "renders 400 with json message" do
          post :create, params: { amount: 10, stripeToken: 'foo', stripeEmail: 'bar', description: 'hi', metadata: {bat: :baz} }
          expect(response.status).to eq(400)
          expect(response.body).to eq(error_json)
        end
      end

      context 'when stripe cannot find or create a customer' do
        before do
          expect(Customer).to receive(:get).and_return nil
          session[:prior_url] = '/prior_url/'
          post :create, params: { amount: 10, stripeToken: 'foo', stripeEmail: 'bar', description: 'hi', metadata: {bat: :baz} }
        end

        it 'renders flash error' do
          expect(flash[:error]).to eq(I18n.t 'charges.unable_to_get_customer')
        end

        include_examples "redirects to prior url"
      end

      let(:valid_params) {{
        amount: 10,
        stripeToken: 'foo',
        stripeEmail: 'bar',
        description: 'hi',
        metadata: {
          bat: 'baz'
        }
      }}

      ChargesController::STRIPE_PARAMS.each do |param|
        context "when params['#{param}'] is missing from request" do
          before do
            post :create, params: valid_params.except(param)
          end

          it "render a json error and returns bad request" do
            expect(response.status).to eq(400)
            json = JSON.parse(response.body)
            expect(json['errors']).to eq("param is missing or the value is empty or invalid: #{param}")
          end
        end
      end

      context "when Charge is successful" do
        let(:requirement) { FactoryBot.create :payment_requirement }
        let(:team) { FactoryBot.create :team, race: requirement.race }

        let(:customer) do
          Stripe::Customer.create({
            card: stripe_helper.generate_card_token,
            email: team.user.email,
            metadata: {
              user_id: team.user.id
            }
          })
        end

        let(:charge) do
          Stripe::Charge.create({
            customer:    customer.id,
            amount:      7000,
            currency:    'usd',
            description: 'Registration Fee for Arizona Quints | Chiditarod X',
            metadata: {
              race_name: team.race.name,
              team_name: team.name,
              requirement_id: requirement.id,
              team_id: team.id
            }
          })
        end

        let(:amount) { '7000' }

        before do
          StripeMock.start
          expect(Customer).to receive(:get).and_return(customer)
          expect(Stripe::Charge).to receive(:create).and_return(charge)
          session[:prior_url] = '/prior_url/'

          expect(CompletedRequirement.count).to eq(0)

          post :create, params: { amount: amount, stripeToken: 'foo', stripeEmail: customer.email, description: 'hi', metadata: {
              team_id: team.id,
              requirement_id: requirement.id
            }.to_json }
        end
        after { StripeMock.stop }

        it 'stores the charge details in cr_metadata' do
          cr_metadata = {
            'customer_id' => customer.id,
            'charge_id' => charge.id,
            'amount' => amount
          }
          expect(assigns(:cr_metadata)).to eq(cr_metadata)
        end

        it 'creates and saves the completed_requirement' do
          # this is brittle, but we need something.
          expect(CompletedRequirement.count).to eq(1)
        end

        it 'renders flash notice' do
          expect(flash[:notice]).to eq('Your card has been charged successfully.')
        end

        include_examples "redirects to prior url"
      end

      shared_examples 'sets_flash_error' do
        it 'renders appropriate flash error' do
          expect(flash[:error]).to match(expected_flash_error)
        end
      end

      context "Stripe Errors" do
        before do
          StripeMock.start
          expect(Customer).to receive(:get).and_return(customer)
          expect(StripeHelper).to receive(:log_and_return_error)
          session[:prior_url] = '/prior_url/'
        end
        after { StripeMock.stop }

        let(:customer) do
          Stripe::Customer.create({
            card: stripe_helper.generate_card_token,
            email: 'musher@chiditarod.com',
            metadata: {
              user_id: 1
            }
          })
        end

        context "Stripe returns invalid request" do
          before do
            expect(Stripe::Charge).to receive(:create).and_raise(Stripe::InvalidRequestError.new(I18n.t("foo"), :foo))
            post :create, params: { amount: 10, stripeToken: 'foo', stripeEmail: customer.email, description: 'hi', metadata: {bat: :baz}.to_json }
          end

          let(:expected_flash_error) { /Invalid parameters supplied to Stripe API/ }
          include_examples "redirects to prior url"
        end

        context "Stripe returns API connection error" do
          before do
            expect(Stripe::Charge).to receive(:create).and_raise(Stripe::APIConnectionError.new("foo", :foo))
            post :create, params: { amount: 10, stripeToken: 'foo', stripeEmail: customer.email, description: 'hi', metadata: {bat: :baz}.to_json }
          end

          let(:expected_flash_error) { /There is an issue connecting to the Stripe API/ }
          include_examples "redirects to prior url"
        end

        context "Stripe returns generic StripeError" do
          before do
            expect(Stripe::Charge).to receive(:create).and_raise(Stripe::StripeError.new("foo", :foo))
            post :create, params: { amount: 10, stripeToken: 'foo', stripeEmail: customer.email, description: 'hi', metadata: {bat: :baz}.to_json }
          end

          let(:expected_flash_error) { "An error occured connecting to Stripe. Please email dogtag@chiditarod.org." }
          include_examples "redirects to prior url"
        end

        context "Something raises an uncaught error" do
          before do
            expect(Stripe::Charge).to receive(:create).and_raise
            post :create, params: { amount: 10, stripeToken: 'foo', stripeEmail: customer.email, description: 'hi', metadata: {bat: :baz}.to_json }
          end

          let(:expected_flash_error) { "An error unrelated to processing your credit card has occured. Please email dogtag@chiditarod.org." }
          include_examples "redirects to prior url"
        end

        ERRORS = [
          :incorrect_number, :invalid_number, :invalid_expiry_month, :invalid_expiry_year,
          :invalid_cvc, :expired_card, :incorrect_cvc, :card_declined, :missing, :processing_error
        ]
        ERRORS.each do |e|
          context "when Stripe::CardError #{e}" do
            before do
              StripeMock.prepare_card_error(e)
              post :create, params: { amount: 10, stripeToken: 'foo', stripeEmail: customer.email, description: 'hi', metadata: {bat: :baz}.to_json }
            end

            it 'assigns customer' do
              expect(assigns(:customer)).to eq(customer)
            end

            let(:expected_flash_error) { I18n.t "charges.#{e}" }
            include_examples "redirects to prior url"
          end
        end
      end
    end

    describe '#refund' do

      let(:valid_user) { FactoryBot.create :refunder_user }

      let(:cr)   { FactoryBot.create :completed_requirement }
      let(:req)  { cr.requirement }
      let(:team) { cr.team }

      let(:customer) do
        Stripe::Customer.create({
          card: stripe_helper.generate_card_token,
          email: team.user.email,
          metadata: {
            user_id: team.user.id
          }
        })
      end

      let(:charge) do
        Stripe::Charge.create({
          customer:    customer.id,
          amount:      7000,
          currency:    'usd',
          description: 'Registration Fee for Arizona Quints | Chiditarod X',
          metadata: {
            race_name: team.race.name,
            team_name: team.name,
            requirement_id: req.id,
            team_id: team.id
          }
        })
      end

      before do
        session[:prior_url] = '/prior_url/'
        StripeMock.start
      end
      after { StripeMock.stop }

      context 'when session[:prior_url] is not set' do
        let(:error_json) {{ errors: "The calling controller should set session[:prior_url] so this method knows where to return to. e.g. session[:prior_url] = request.original_url"}.to_json}
        it "renders 400 with json message" do
          session.delete(:prior_url)
          post :refund, params: { charge_id: charge.id }
          expect(response.status).to eq(400)
          expect(response.body).to eq(error_json)
        end
      end

      context 'when the charge is not found' do
        it 'renders 404' do
          post :refund, params: { charge_id: 0 }
          expect(response.status).to eq(404)
        end
      end

      context 'when charge is found and already refunded' do
        let(:error_json) {{ error: "Charge ID #{charge.id} is already refunded" }.to_json}
        it 'renders 400 with json message' do
          charge.refund
          post :refund, params: { charge_id: charge.id }
          expect(response.status).to eq(400)
          expect(response.body).to eq(error_json)
        end
      end

      context 'when the charge tries to be refunded but fails' do
        let(:error_json) {{ error: "Charge ID: #{charge.id} could not be refunded. No action taken." }.to_json}
        it 'renders 500 with json message' do
          expect(charge).to receive(:refund).and_raise(StandardError)
          expect(Stripe::Charge).to receive(:retrieve).with(charge.id).and_return(charge)
          post :refund, params: { charge_id: charge.id }
          expect(response.status).to eq(500)
          expect(response.body).to eq(error_json)
        end
      end

      context 'when the refund is successful' do
        let(:flash_msg) { "The refund has processed successfully" }

        it 'does not delete the CompletedRequirement object, sets flash notice, and redirects to prior url' do
          expect(CompletedRequirement).to_not receive(:delete_by_charge).with(charge)
          post :refund, params: { charge_id: charge.id }
          expect(flash[:notice]).to eq(flash_msg)
          expect(response).to redirect_to('/prior_url/')
        end

        context 'when delete_completed_requirement is passed' do

          context 'and the user is an admin' do
            let(:the_user)  { FactoryBot.create :admin_user }
            let(:flash_msg) { "The refund has processed successfully, and the completed requirement was deleted" }

            it 'deletes the CompletedRequirement object, sets flash notice, and redirects to prior url' do
              expect(CompletedRequirement).to receive(:delete_by_charge)
              post :refund, params: { charge_id: charge.id, delete_completed_requirement: true }
              expect(flash[:notice]).to eq(flash_msg)
              expect(response).to redirect_to('/prior_url/')
            end
          end

          context 'when the user is not an admin' do
            let(:flash_msg) { "The refund has processed successfully, but the completed requirement was not deleted because you do not have the appropriate permissions" }

            it 'does not delete the CompletedRequirement object, sets flash notice, and redirects to prior url' do
              expect(CompletedRequirement).to_not receive(:delete_by_charge).with(charge)
              post :refund, params: { charge_id: charge.id, delete_completed_requirement: true }
              expect(flash[:notice]).to eq(flash_msg)
              expect(response).to redirect_to('/prior_url/')
            end
          end
        end
      end
    end
  end
end
