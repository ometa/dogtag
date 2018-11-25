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
# Base model to be overridden by more specific requirements.
class Requirement < ApplicationRecord
  validates_presence_of :name

  belongs_to :race
  validates_presence_of :race

  has_many :completed_requirements
  has_many :teams, :through => :completed_requirements

  ALLOWED_TYPES = [['Payment', 'PaymentRequirement']]

  class << self
    def allowed_types
      ALLOWED_TYPES
    end
  end

  def enabled?
    raise "Implement Me!"
  end

  def cr_for(team)
    record = CompletedRequirement.where(:team_id => team.id, :requirement_id => id).first
    record.present? ? record : nil
  end

  def completed?(team)
    CompletedRequirement.where(:team_id => team.id, :requirement_id => id).present?
  end

  # todo: figure out how to allow only child classes to call this method.
  # todo: move JSON and is_a? Hash calls into the model
  def complete(team_id, user, metadata = {})
    cr = CompletedRequirement.new(
      :requirement_id => id,
      :team_id => team_id,
      :user => user,
      :metadata => JSON.generate(metadata)
    )
    cr.subscribe(CompletedRequirementAuditor.new)
    return cr if cr.save
    false
  end
end
