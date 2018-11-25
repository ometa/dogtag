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
class Race < ApplicationRecord
  validates_presence_of :name, :max_teams, :people_per_team
  validates_presence_of :race_datetime, :registration_open, :registration_close, :final_edits_close
  validates :max_teams, :people_per_team, :numericality => {
    :only_integer => true,
    :greater_than => 0
  }
  validates :classy_campaign_id, :classy_default_goal, numericality: {
    only_integer: true,
    greater_than: 0,
    allow_nil: true
  }
  validates_uniqueness_of :name
  validates_with RaceValidator

  # todo: validate filter_field based on contents of jsonform schema

  scope :past,    -> { where("race_datetime < ?", Time.zone.now) }
  scope :current, -> { where("race_datetime > ?", Time.zone.now) }

  has_many :teams
  MAX_TEAMS_PER_RACE = 4096 # arbitrary number of maximum teams per race.

  # Each race has different registration requirements that needs
  # to be fulfilled before a team is fully registered.
  has_many :requirements

  def question_fields
    return [] unless jsonform.present?
    JSON.parse(jsonform)['schema']['properties'].keys
  rescue => e
    Rails.logger.error "Could not retrieve possible jsonschema filter fields: #{e}"
    []
  end

  def filter_field_array
    return [] if filter_field.nil?
    filter_field.split(',')
  end

  def enabled_requirements
    requirements.select(&:enabled?)
  end

  def finalized_teams
    Team.all_finalized.where(race_id: id)
  end

  def spots_remaining
    max_teams - finalized_teams.size
  end

  def waitlist_count
    return 0 if not_full?
    teams.size - max_teams
  end

  def over?
    race_datetime < Time.zone.now
  end

  def full?
    finalized_teams.size >= max_teams
  end

  def not_full?
    !full?
  end

  def not_yet_open?
    Time.zone.now < registration_open
  end

  def open_for_registration?
    now = Time.zone.now
    return false if now < registration_open
    return false if now > registration_close
    true
  end

  def registration_over?
    registration_close < Time.zone.now
  end

  def in_final_edits_window?
    now = Time.zone.now
    return false if now < registration_close
    return false if now > final_edits_close
    true
  end

  def registerable?
    not_full? && open_for_registration?
  end

  def days_before_close
    t = Time.zone.now
    return false if registration_close < t
    (registration_close - t).ceil
  end

  def stats
    money_raised = teams.reduce(0) do |memo, team|
      memo + team.money_paid_in_cents
    end

    {
      'money_raised' => money_raised
    }
  end
end
