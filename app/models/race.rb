class Race < ActiveRecord::Base
  include Wisper.model

  validates_presence_of :name, :max_teams, :people_per_team
  validates_presence_of :race_datetime, :registration_open, :registration_close
  validates :max_teams, :people_per_team, :numericality => {
    :only_integer => true,
    :greater_than => 0
  }
  validates_uniqueness_of :name
  validates_with RaceValidator

  # todo: validate filter_field based on contents of jsonform schema

  scope :past,    -> { where("race_datetime < ?", Time.now) }
  scope :current, -> { where("race_datetime > ?", Time.now) }

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
    return true if race_datetime < Time.now
  end

  def full?
    finalized_teams.size >= max_teams
  end

  def not_full?
    !full?
  end

  def open_for_registration?
    now = Time.now
    return false if now < registration_open
    return false if registration_close < now
    true
  end

  def registration_over?
    registration_close < Time.now
  end

  def registerable?
    not_full? && open_for_registration?
  end

  def days_before_close
    t = Time.now
    return false if registration_close < t
    (registration_close - t).ceil
  end

  class << self

    def load_stats(race_id)
      race = Race.find race_id
      money_raised = race.teams.reduce(0) { |memo, t| memo + t.money_paid_in_cents }
      {
        'money_raised' => money_raised
      }
    end

    def find_registerable_races
      Race.all.select(&:registerable?)
    end

    def find_open_races
      Race.all.select(&:open_for_registration?)
    end
  end
end
