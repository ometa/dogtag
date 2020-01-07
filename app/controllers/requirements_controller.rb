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
class RequirementsController < ApplicationController
  before_filter :require_user

  load_and_authorize_resource :race
  load_and_authorize_resource :requirement, :through => :race

  def destroy
    @requirement = Requirement.find params[:id]
    try_to_delete(@requirement, race_url(id: @requirement.race.id))
  end

  def update
    @requirement = Requirement.find(params[:id])
    @race = @requirement.race
    try_to_update(@requirement, requirement_params, edit_race_url(@requirement.race.id))
  end

  def edit
    @requirement = Requirement.find params[:id]
    @race = @requirement.race
  end

  def new
    @race = Race.find params[:race_id]
    @requirement = Requirement.new
    @requirement.race = @race
  end

  def create
    return render :status => 400 if params[:requirement].blank?

    @race = Race.find params[:race_id]
    return render :status => 400 if @race.nil?

    @requirement = Requirement.new requirement_params
    @requirement.race = @race

    if @requirement.save
      flash[:notice] = I18n.t('create_success')
      redirect_to edit_race_requirement_url(:race_id => @requirement.race.id, :id => @requirement.id)
    else
      flash.now[:error] = [t('create_failed')]
      flash.now[:error] << @requirement.errors.messages
    end
  end

  private

  def requirement_params
    params.require(:requirement).permit(:name, :type, style_ids: [])
  end
end
