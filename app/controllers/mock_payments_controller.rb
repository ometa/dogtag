class MockPaymentsController < ApplicationController
  # Mock payment controller for testing - doesn't connect to Stripe
  # Only available in development and test environments

  before_action :ensure_dev_or_test_environment

  def create
    team = Team.find(params[:team_id])
    requirement = Requirement.find(params[:requirement_id])
    mock_behavior = params[:mock_behavior] || 'success'

    authorize! :create, :charges

    if mock_behavior == 'success'
      # Complete the payment requirement
      cr = requirement.complete(
        team.id,
        current_user,
        {
          'charge_id' => "mock_ch_#{SecureRandom.hex(12)}",
          'amount' => params[:amount].to_i,
          'mock' => true
        }
      )

      if cr
        flash[:success] = "Mock payment successful!"
        redirect_to team_path(team)
      else
        flash[:error] = "Mock payment failed to save"
        redirect_to team_path(team)
      end
    else
      # Mock failure
      flash[:error] = "Mock payment declined"
      redirect_to team_path(team)
    end
  end

  private

  def ensure_dev_or_test_environment
    unless Rails.env.development? || Rails.env.test?
      flash[:error] = "Mock payments are only available in development and test environments"
      redirect_to root_path
    end
  end
end
