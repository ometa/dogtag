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
class TeamsController < ApplicationController
  before_action :require_user
  before_action :set_no_cache, only: %w{show edit search}

  load_and_authorize_resource

  def search
    if params[:q].present?
      query = params[:q].parameterize
      @teams = Team.where('name ILIKE ?', "%#{query}%")
    else
      @teams = Team.none
    end

    respond_to do |format|
      format.json { render json: @teams.map { |team| { id: team.id, text: "#{team.name} - #{team.race.name}" } } }
    end
  end

  def index
    @myteams = Team.where(:user => current_user).order(created_at: :desc)
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
    return render :status => :bad_request if params[:team].blank?

    @team = Team.new(team_params)
    @team.subscribe(TeamAuditor.new)

    @team.user = current_user
    race_id = params[:race_id] || session[:signup_race_id]
    @team.race ||= Race.find(race_id)

    if @team.save
      flash.now[:notice] = I18n.t('create_success')
      redirect_to team_questions_path(@team)
    else
      flash.now[:error] = [t('create_failed')]
      flash.now[:error] << @team.errors.messages
    end
  end

  def show
    @team = Team.find params[:id]
    @race = @team.race

    if @team.finalized && @team.user == current_user
      @display_notification = :notify_now_complete
    end

    # currently required by charges controller to know where to redirect
    # the user after performing an action
    session[:prior_url] = request.original_url
  end

  alias edit show

  def update
    @team = Team.find(params[:id])
    @team.subscribe(TeamAuditor.new)
    @race = @team.race

    @team.on(:update_team_successful) do |team|
      if team.completed_questions?
        flash[:notice] = I18n.t('update_success')
        redirect_to(team_path(team))
      else
        flash[:notice] = I18n.t('teams.update.success_fill_out_questions')
        redirect_to(team_questions_path(team))
      end
    end

    @team.on(:update_team_failed) do |team|
      flash.now[:error] = [I18n.t('update_failed')]
      flash.now[:error] << team.errors.messages
    end

    @team.update(team_params)
  end

  # TODO: only allow delete if no payments
  def destroy
    @team = Team.find params[:id]
    @team.subscribe(TeamAuditor.new)
    try_to_delete(@team, teams_path)
  end

  private

  def team_params
    params
      .require(:team)
      .permit(:race_id, :name, :description, :experience)
  end
end
