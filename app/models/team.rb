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
class Team < ApplicationRecord
  validates :name, :description, presence: true
  validates :name, length: { :maximum => 1000, :message => "of your team is a bit long, eh? Keep it to 1000 characters or less." }
  validates :name, uniqueness: { :scope => [:race], :message => 'should be unique per race' }
  validates :experience, presence: true
  validates :experience, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0 }
  validates_with TeamValidator

  include Wisper.model

  belongs_to :user
  belongs_to :race
  validates :user, :race, presence: true

  # A team has a certain number of people, per the settings for the race.
  has_many :people

  # A team must track which race requirements have been fulfilled.
  has_many :completed_requirements
  has_many :requirements, :through => :completed_requirements

  scope :all_finalized,   -> { where('teams.finalized = ?', true) }
  scope :all_unfinalized, -> { where('teams.finalized IS NULL') }
  scope :belonging_to, ->(user_id) { where("user_id = ?", user_id) }

  EXPERIENCE_LEVELS = [
    "Zero. Fresh meat",
    "1st year veterans",
    "2nd year sophmorons",
    "3rd year's a charm",
    "4th year senioritis",
    "5th year repeat offenders",
    "6th year and we're still drunk",
    "7th years of good luck",
    "8th year elite",
    "9th year elders",
    "10th year anniversary",
    "11th year OGs",
    "12th year sages",
    "13th year fingers crossed",
    "14th year clumsy adolescents",
    "15th year student drivers",
    "Sweet 16th",
    "17th year.. wait, what?",
    "18th year I'M AN ADULT",
    "19th year wait are you seriously still doing this?",
    "XX",
    "21st year finally legal"
  ]

  def unfinalized
    ! finalized
  end

  # sets the finalization bits and triggers follow-up actions
  # return nil if the team is not a candidate for finalization
  def finalize
    return nil if finalized
    return nil unless meets_finalization_requirements?

    self.notified_at = Time.zone.now
    self.assigned_team_number = self.assigned_team_number || next_available_team_num
    self.finalized = true

    if self.save
      Workers::TeamFinalizer.perform_async({'team_id' => self.id})
      Rails.logger.info "Finalized Team: #{name} (id: #{id})"
      true
    else
      msg = "Failed to finalize team: #{name}"
      Rails.logger.error(msg)
      raise StandardError, msg
    end
  end

  # this removes the finalization bits from the team
  # return nil if the team is not a candidate for unfinalization
  def unfinalize(force=false)
    if ! force
      return nil unless finalized
      return nil if meets_finalization_requirements?
    end

    self.notified_at = nil
    self.finalized = nil
    self.save
  end

  def person_experience
    people.reduce(0) { |memo, person| person.experience + memo }
  end

  def percent_complete
    total = race.requirements.select(&:enabled?).size + race.people_per_team
    total += 1 if race.jsonform.present?

    var = people.size + requirements.size
    var += 1 if jsonform.present?
    (var * 100) / total
  end

  def needs_people?
    (race.people_per_team - people.count) > 0
  end

  def is_full?
    ! needs_people?
  end

  # todo: make more generic,
  # this relies on the presence of metadata['amount'] in the completed requirement
  def money_paid_in_cents
    completed_requirements.reduce(0) do |memo, cr|
      memo + cr.metadata.fetch('amount').to_i
    end
  end

  def completed_questions?
    jsonform.present? || race.jsonform.blank?
  end

  def jsonform_value(key)
    return nil if jsonform.nil?
    @jsonform_hash ||= JSON.parse(jsonform)
    @jsonform_hash[key]
  end

  def completed_all_requirements?
    return true if race.requirements.blank?
    race.requirements.select(&:enabled?) == requirements
  end

  def meets_finalization_requirements?
    completed_questions? && is_full? && completed_all_requirements?
  end

  # todo spec
  def has_saved_answers?
    jsonform.present?
  end

  # TODO - finish this
  def waitlist_position
    # assume we are not on the waitlist if race is not full
    return false if race.not_full?
    # assume we are not on the waitlist if our requirements are met
    return false if finalized
  end

  private

  def next_available_team_num
    teams = Team.where(race_id: race.id).where('teams.assigned_team_number IS NOT NULL')
    used_numbers = teams.map(&:assigned_team_number).compact

    (1..Race::MAX_TEAMS_PER_RACE).detect do |n|
      ! used_numbers.include?(n)
    end
  end


  class << self
    # todo: spec
    def export(race_id, options = {})
      race = Race.find(race_id)
      person_keys = %w(first_name last_name email phone twitter experience)
      user_keys = %w(first_name last_name email phone stripe_customer_id)

      table = []
      table << make_header(race, person_keys, user_keys)
      table.concat(make_body(race, options, person_keys, user_keys))
    end

    private

    def make_body(race, options, person_keys, user_keys)
      teams = options[:finalized] ? race.finalized_teams : race.teams
      teams.inject([]) do |memo, team|
        row = []
        row << team.finalized.to_s
        row << team.assigned_team_number.to_s

        cols = [].concat(Team.attribute_names.select do |n|
          %w(name experience description).include?(n)
        end)

        # team basics
        row.concat cols.map{ |n| team[n] }

        # race-specific details
        row.concat race.question_fields.map{ |n| team.jsonform_value(n) }

        # user info
        row.concat user_keys.map{ |k| team.user[k] }

        # racers
        race.people_per_team.times do |i|
          row.concat person_keys.map{ |k| team.people[i].present? ? team.people[i][k] : '' }
        end

        memo << row
      end
    end

    def make_header(race, person_keys, user_keys)
      header = []
      header << 'finalized'
      header << 'number'

      # team basics
      header.concat(Team.attribute_names.select do |n|
        %w(name experience description).include?(n)
      end)

      # race-specific details
      header.concat race.question_fields.map{ |n| n.humanize }

      # user info
      header.concat user_keys.map{ |k| "user_#{k}" }

      # racers
      race.people_per_team.times do |i|
        header.concat person_keys.map{ |k| "dawg_#{i}_#{k}" }
      end

      header
    end
  end
end
