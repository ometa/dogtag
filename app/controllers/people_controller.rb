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
class PeopleController < ApplicationController
  before_action :require_user
  load_and_authorize_resource

  def destroy
    @person = Person.find params[:id]
    @team = @person.team

    if @team.meets_finalization_requirements?
      flash[:error] = I18n.t("people.destroy.team_complete")
      return redirect_to team_url(id: @team.id)
    end

    @person.subscribe(PersonAuditor.new)
    try_to_delete(@person, team_url(id: @team.id))
  end

  def update
    @person = Person.includes(:team).find(params[:id])
    @team = @person.team
    @person.subscribe(PersonAuditor.new)
    try_to_update(@person, person_params, team_url(@person.team.id))
  end

  def edit
    @person = Person.includes(:team).find(params[:id])
    @team = @person.team
  end

  def new
    @team = Team.find params[:team_id]
    @person = Person.new
  end

  def create
    return render :status => :bad_request if params[:person].blank?

    @team = Team.find params[:team_id]
    @person = Person.new(person_params)
    @person.subscribe(PersonAuditor.new)
    @person.team = @team

    if @person.save
      flash[:notice] = I18n.t('create_success')
      redirect_to team_url :id => @person.team.id
    else
      flash.now[:error] = [t('create_failed')]
      flash.now[:error] << @person.errors.messages
    end
  end

  private

  def person_params
    params
      .require(:person)
      .permit(:first_name, :last_name, :email, :phone, :twitter, :experience, :zipcode)
  end
end
