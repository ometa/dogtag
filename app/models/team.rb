class Team < ActiveRecord::Base
  validates_presence_of :name, :description
  validates_length_of :name, :maximum => 1000, :message => "of your team is a bit long, eh? Keep it to 1000 characters or less."
  validates_uniqueness_of :name, :scope => [:race], :message => 'should be unique per race'
  validates_uniqueness_of :twitter, :scope => [:race], :allow_nil => true, :allow_blank => true, :message => 'needs to be unique per race'
  validates_format_of :twitter, :with => /\A^@\w+\z/i, :allow_nil => true, :allow_blank => true, :message => 'needs to begin with @, be a single, word, and not have weird characters'

  belongs_to :user
  belongs_to :race
  validates_presence_of :user, :race

  # A team has a certain number of people, per the settings for the race.
  has_many :people

  # A team must track which race requirements have been fulfilled.
  has_many :completed_requirements
  has_many :requirements, :through => :completed_requirements

  # Other fields (originally JsonForm-bound but whatevs)

  VALID_RACER_TYPES = %w(racer art_cart)

  validates_presence_of :racer_type, :primary_inspiration, :experience
  validates_acceptance_of :rules_confirmation, :sabotage_confirmation,
    :cart_deposit_confirmation, :food_confirmation, :accept => true
  validates :experience, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0 }
  validates_inclusion_of :racer_type, in: VALID_RACER_TYPES
  validates_length_of :buddies, :maximum => 255, :message => "list is a bit long, eh? The max is 255 characters."

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
    "10th year anniversary"
  ]

  INSPIRATIONS = [
    "Industrial Design", 'Building Cool Stuff', 'Doing a good thing but doing it all wrong',
    "Speed / 1st Place", "Art", "Costuming & Themes", 'Participatory Culture',
    "Contests", "Charity", "Pleasure", "Sabotage", "Spectacle",
    "Fundraising", "Foodraising", "The Experience, Man", "I am heavily uninspired", 'DFL'
  ]

  def percent_complete
    total = race.requirements.select(&:enabled?).size + race.people_per_team
    var = people.size + requirements.size
    (var * 100) / total
  end

  def needs_people?
    (race.people_per_team - people.count) > 0
  end

  def is_full?
    ! needs_people?
  end

  def completed_all_requirements?
    return true if race.requirements.blank?
    race.requirements.select(&:enabled?) == requirements
  end

  def finalized?
    completed_all_requirements? && is_full?
  end

  # TODO - finish this
  def waitlist_position
    # assume we are not on the waitlist if race is not full
    return false if race.not_full?
    # assume we are not on the waitlist if our requirements are met
    return false if finalized?
  end

  class << self
    def racer_types_optionlist
      VALID_RACER_TYPES.map { |r| [r.to_s.humanize, r] }
    end

    # todo: spec
    def export(race_id, options = {})
      race = Race.find race_id
      person_keys = %w(first_name last_name email phone twitter experience)
      user_keys = %w(first_name last_name email phone stripe_customer_id)

      header = []
      header << 'finalized'

      header.concat(Team.attribute_names.reject do |n|
        %w(created_at	updated_at notified_at race_id).include? n
      end)

      race.people_per_team.times do |i|
        header.concat person_keys.map{ |k| "dawg_#{i}_#{k}" }
      end

      header.concat user_keys.map{ |k| "user_#{k}" }

      # body
      regs = options[:finalized] ? race.finalized_teams : race.teams
      regs.inject(Array.new << header) do |total, reg|
        row = []
        row << reg.finalized?

        cols = []
        cols.concat(Team.attribute_names.reject do |n|
          %w(created_at	updated_at notified_at race_id).include? n
        end)

        row.concat cols.map{ |n| reg[n] }

        race.people_per_team.times do |i|
          row.concat person_keys.map{ |k| reg.people[i].present? ? reg.people[i][k] : '' }
        end

        row.concat user_keys.map{ |k| reg.team.user[k] }

        # finally..
        total << row
      end
    end
  end
end
