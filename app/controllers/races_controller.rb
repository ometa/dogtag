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
require 'csv'

class RacesController < ApplicationController
  before_filter :require_user, :except => [:index, :show]
  load_and_authorize_resource

  def index
    @past_races = Race.past.order('created_at DESC').includes(:teams)
    @current_races = Race.current.order('created_at DESC').includes(:teams)
  end

  def show
    @race = Race.find id_params[:id]
    if current_user
      @my_race_teams = Team.belonging_to(current_user.id).where(race_id: @race.id)
      if current_user.is_any_of?(:admin, :operator)
        @stats = @race.stats
      end
    end
  end

  alias edit show

  def new
    @race = Race.new
  end

  def registrations
    @race = Race.find(params.require(:race_id)[:race_id])
    @finalized_teams = Team.all_finalized.where(race_id: @race.id).order('updated_at DESC').includes(:people)
    @waitlisted_teams = Team.all_unfinalized.where(race_id: @race.id).order('updated_at DESC').includes(:people)
  end

  def export
    export_params = params.require(:race_id).permit(:finalized)
    #return render :status => 400 if params[:race_id].blank?

    race_id = export_params[:race_id]
    teams = export_params[:finalized] ? Team.export(race_id, :finalized => true) : Team.export(race_id)
    data = CSV.generate do |csv|
      teams.each { |i| csv << i }
    end
    send_data data, :type => 'text/csv; charset=utf-8; header=present', :disposition => "attachment; filename=race_#{race_id}_export.csv"
  end

  def create
    #return render :status => 400 if params[:race].blank?

    @race = Race.new(parse_filter_field_param(race_params))

    if @race.save
      flash[:notice] = I18n.t('create_success')
      return redirect_to races_path
    else
      flash.now[:error] = [t('create_failed')]
      flash.now[:error] << @race.errors.messages
    end
  end

  def update
    @race = Race.find(id_params[:id])
    try_to_update(@race, parse_filter_field_param(race_params), edit_race_url(@race))
  end

  def destroy
    @race = Race.find(id_params[:id])
    try_to_delete(@race, races_path)
  end

  private

  def parse_filter_field_param(hash)
    if hash[:filter_field].present?
      hash[:filter_field] = hash[:filter_field].reject{|f| f.empty?}.join(',')
    end
    hash
  end


  def id_params
    params.require(:id)
  end

  def race_params
    params.
      require(:race).
      permit(:name, :max_teams, :people_per_team,
             :race_datetime, :registration_open, :registration_close, :final_edits_close,
             :classy_campaign_id, :classy_default_goal,
             :jsonform, {filter_field: []}
      )
  end
end
