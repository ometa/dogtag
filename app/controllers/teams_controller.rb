class TeamsController < ApplicationController
  before_filter :require_user
  load_and_authorize_resource

  def index
    @myteams = Team.where(:user => current_user)
    if params[:race_id].present?
      begin
        @race = Race.find params[:race_id]
        @myteams = @myteams.where(:race_id => @race.id)
      rescue ActiveRecord::RecordNotFound
        flash[:error] = "Race not found"
      end
    end
  end

  def new
    unless params[:race_id]
      flash[:error] = I18n.t('must_select_race')
      return redirect_to races_path
    end

    session[:signup_race_id] = params[:race_id]
    @race = Race.find(params[:race_id])
    @team = Team.new
    @team.race = @race
  end

  def create
    return render :status => 400 if params[:team].blank?

    @team = Team.new team_params

    @team.user = current_user
    race_id = params[:race_id] || session[:signup_race_id]
    @team.race ||= Race.find(race_id)

    if @team.save
      flash.now[:notice] = I18n.t('create_success')
      return redirect_to team_url(@team.id)
    else
      flash.now[:error] = [t('create_failed')]
      flash.now[:error] << @team.errors.messages
    end
  end

  def show
    @team = Team.find params[:id]

    # if this team is finalized and the user hasn't
    # been notified (e.g. newly finalized)
    process_if_newly_finalized

    # if this team is now unfinalized for some reason,
    # unset the notification bit so they can be again notified in the future.
    unprocess_if_newly_unfinalized

    @race = @team.race
    session[:prior_url] = request.original_url
  end

  alias edit show

  def update
    @team = Team.find params[:id]
    @race = @team.race

    if @team.update_attributes team_params
      flash[:notice] = I18n.t('update_success')
      return redirect_to team_url(@team.id)
    else
      flash.now[:error] = [t('update_failed')]
      flash.now[:error] << @team.errors.messages
    end
  end

  # TODO: only allow delete if no payments
  def destroy
    @team = Team.find params[:id]

    if @team.destroy
      flash[:notice] = t 'delete_success'
      redirect_to teams_path
    else
      flash[:error] = t '.delete_failed'
    end
  end

  private

  def team_params
    params.require(:team).permit(
      :race_id,
      :name, :description, :twitter, :racer_type,
      :primary_inspiration, :rules_confirmation, :sabotage_confirmation,
      :cart_deposit_confirmation, :food_confirmation, :experience,
      :buddies, :wildcard, :private_comments
    )
  end

  # TODO: move emailer to observer pattern?
  def process_if_newly_finalized
    if @team.finalized? && @team.notified_at.blank? && @team.user == current_user
      @team.notified_at = Time.now
      if @team.save
        UserMailer.team_finalized_email(current_user, @team).deliver
        Rails.logger.info "Finalized Team: #{@team.name} (id: #{@team.id})"
        @display_notification = :notify_now_complete
      else
        Rails.logger.error "Failed to set notified_at for #{reg}"
      end
    end
  end

  # TODO: move this to observer pattern?
  def unprocess_if_newly_unfinalized
    if !@team.finalized? && @team.notified_at.present?
      @team.notified_at = nil
      @team.save
    end
  end
end
