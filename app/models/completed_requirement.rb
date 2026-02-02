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
# Intermediate model between a Team and Requirement
# User indicates which user made the association
class CompletedRequirement < ApplicationRecord

  include Wisper.model

  belongs_to :team
  belongs_to :requirement
  belongs_to :user

  validates :team, :requirement, :user, presence: true
  validates :team, uniqueness: { :scope => [:requirement], :allow_nil => true, :message => 'has already completed this requirement.' }
  validates :requirement, uniqueness: { :scope => [:team], :allow_nil => true, :message => 'has already been completed for that team' }

  # todo: use postgres native json field type, here.
  serialize :metadata, coder: JSON

  def metadata
    m = read_attribute :metadata
    return m if m.is_a?(Hash)
    return JSON.load(m)
  end

  # lookup a completed requirement by a stripe charge and delete it.
  def self.delete_by_charge(charge)

    req_id = charge['metadata']['requirement_id']

    # we used to have a registration table that linked a team (to be used more than once) to a race. we later
    # removed the registration table in favor of a single-use team object that registers for a single race.
    # We used to store the registration_id in stripe, and later changed to a team_id but kept support for
    # loading registration_id for older datasets.
    team_id = charge['metadata']['team_id'] || charge['metadata']['registration_id']

    # TODO: Introduce papertrail on completed requirement to track when the requirement is deleted and by whom
    if cr = CompletedRequirement.where(requirement_id: req_id, team_id: team_id).first
      cr.subscribe(CompletedRequirementAuditor.new)
      cr.destroy
    end
  end
end
