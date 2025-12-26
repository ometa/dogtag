class MockPaymentsController < ApplicationController
  # Mock payment controller for testing - doesn't connect to Stripe

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
end
