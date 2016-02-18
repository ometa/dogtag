class Team < ActiveRecord::Base
  validates_presence_of :name, :description
  validates_length_of :name, :maximum => 1000, :message => "of your team is a bit long, eh? Keep it to 1000 characters or less."
  validates_uniqueness_of :name, :scope => [:race], :message => 'should be unique per race'
  validates_presence_of :experience
  validates :experience, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0 }
  validates_with TeamValidator

  belongs_to :user
  belongs_to :race
  validates_presence_of :user, :race

  # A team has a certain number of people, per the settings for the race.
  has_many :people

  # A team must track which race requirements have been fulfilled.
  has_many :completed_requirements
  has_many :requirements, :through => :completed_requirements

  scope :all_finalized,   -> { where('teams.finalized = ?', true) }
  scope :all_unfinalized, -> { where('teams.finalized IS NULL') }

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
    "11th year OGs"
  ]

  def unfinalized
    ! finalized
  end

  # sets the finalization bits and triggers follow-up actions
  def finalize
      puts "a"
    return nil if finalized
      puts "b"
    return nil unless meets_finalization_requirements?
      puts "c"
    # finalize
    self.notified_at = Time.now
    self.assigned_team_number = self.assigned_team_number || next_available_team_num
    self.finalized = true

    if self.save
      puts "saved"
      # todo: move mailer to async process
      UserMailer.team_finalized_email(self.user, self).deliver_now
      Rails.logger.info "Finalized Team: #{name} (id: #{id})"
      true
    else
      msg = "Failed to finalize team: #{name}. Errors: #{self.errors.inspect}"
      Rails.logger.error(msg)
      raise StandardError, msg
    end
  end

  # remove the finalization bits from the team
  def unfinalize
    return nil unless finalized
    # unset the notification field so they can be again notified in the future.
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
    return true if race.jsonform.blank?
    jsonform.present?
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
    completed_all_requirements? && is_full? && completed_questions?
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
