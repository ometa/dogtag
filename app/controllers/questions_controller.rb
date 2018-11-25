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
class QuestionsController < ApplicationController
  before_filter :require_user

  respond_to :json, only: [:create]
  respond_to :html, only: [:show]

  # HACK: get around strong parameters.
  # These are the names of the parameter keys in the Race's jsonschema.
  # TODO: figure out how to calculate this dynamically.
  HACK_PARAM_WHITELIST = [
    :'racer-type', :'primary-inspiration', :'secondary-inspiration', :'twitter', :'buddies', :'private-comments', :'explain-theme',
    :'agree-to-core-philosophy', :'agree-to-rules', :'agree-to-sabotage', :'agree-to-cart-deposit', :'agree-to-cart-food-poundage',
    :'agree-not-a-donation', :'agree-to-orientation', :'flame-effects', :'fundraising', :'referred-by',
    :'party-bus-interest', :'party-bus-seats', :'cart-parking'
  ]

  # this method loads the jsonform data from the team's race
  def show
    authorize! :show, :questions
    @team = Team.find(params.require(:team_id))

    unless @team.race.jsonform.present?
      flash[:info] = I18n.t('questions.none_defined')
      return redirect_to team_path(@team)
    end

    jsonform = JSON.parse(@team.race.jsonform)
    jsonform = JsonForm.add_csrf(jsonform, form_authenticity_token)
    jsonform = JsonForm.add_saved_answers(@team, jsonform, form_authenticity_token)
    @questions = jsonform.to_json
  end

  # this saves the team's jsonform response data
  def create
    authorize! :create, :questions
    @team = Team.find(params.require(:team_id))

    # todo: move this validation logic into model
    unless @team.race.open_for_registration?
      flash[:error] = I18n.t('questions.cannot_modify')
      return redirect_to team_path(@team)
    end

    @team.jsonform = filtered_params.to_json

    if @team.save
      flash[:info] = I18n.t('questions.updated')
      redirect_to team_path(@team)
    else
      Rails.logger.error "Issue saving questions for team ID: #{@team.id} with jsonform: #{@team.jsonform}"
      flash[:error] = I18n.t('questions.could_not_save')
      redirect_to team_questions_path(@team)
    end
  end

  private

  # filter the params by the whitelist and remove any with blank values
  # TODO: change this to slice! and reject! after spec'ing (check if this is done)
  def filtered_params
    params
      .slice(*HACK_PARAM_WHITELIST)
      .reject{ |_k,v| v.blank? }
  end
end
