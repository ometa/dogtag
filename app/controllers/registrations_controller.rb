class RegistrationsController < ApplicationController
  before_filter :require_user
  load_and_authorize_resource

  respond_to :html, :csv

  def new
    unless params[:team_id]
      flash[:error] = I18n.t('must_select_team')
      return redirect_to teams_path
    end

    team_id = session[:team_id] = params[:team_id]
    @race = Race.find params[:race_id]

    @registration = Registration.new
    @registration.name = Team.find(team_id).name   # default team name
  end

  def create
    return render :status => 400 if params[:registration].blank?

    @race = Race.find params[:race_id]
    @registration = Registration.new registration_params
    @registration.race = @race
    #team_id = session[:team_id]
    @registration.team = Team.find session[:team_id]

    if @registration.save
      flash.now[:notice] = I18n.t('create_success')
      return redirect_to race_registration_url(@registration.race.id, @registration.id)
    else
      flash.now[:error] = [t('create_failed')]
      flash.now[:error] << @registration.errors.messages
    end
  end


  def show
    @registration = Registration.find params[:id]

    # if this registration is finalized and the user hasn't
    # been notified (e.g. newly finalized)
    process_if_newly_finalized

    # if this registration is now unfinalized for some reason,
    # unset the notification bit so they can be again notified in the future.
    unprocess_if_newly_unfinalized

    @race = @registration.race
    session[:prior_url] = request.original_url
  end

  alias edit show

  def update
    @registration = Registration.find params[:id]

    if @registration.update_attributes registration_params
      flash[:notice] = I18n.t('update_success')
      return redirect_to race_registration_url(@registration.race.id, @registration.id)
    else
      flash.now[:error] = [t('update_failed')]
      flash.now[:error] << @registration.errors.messages
    end
    @race = @registration.race
  end

  def index
    @race = Race.find params[:race_id]
    @registrations = Registration.where(:race_id => params[:race_id]).order('updated_at DESC')
    @waitlisted_registrations = @registrations.reject(&:finalized?)
  end

  private

  def process_if_newly_finalized
    if @registration.finalized? && @registration.notified_at.blank? && @registration.team.user == current_user
      @registration.notified_at = Time.now
      if @registration.save
        UserMailer.registration_finalized_email(current_user, @registration).deliver
        Rails.logger.info "Registration finalized for #{@registration.name}, ID: #{@registration.id}"
        @display_notification = :notify_now_complete
      else
        Rails.logger.error "Failed to set notified_at for #{reg}"
      end
    end
  end

  def unprocess_if_newly_unfinalized
    if ! @registration.finalized? && @registration.notified_at.present?
      @registration.notified_at = nil
      @registration.save
    end
  end

  def registration_params
    params.require(:registration).
      permit(:name, :description, :twitter, :racer_type,
             :primary_inspiration, :rules_confirmation, :sabotage_confirmation,
             :cart_deposit_confirmation, :food_confirmation, :experience,
             :buddies, :wildcard, :private_comments)
  end

end
