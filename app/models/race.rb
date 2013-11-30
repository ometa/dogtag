class Race < ActiveRecord::Base
  validates_presence_of :name, :max_teams, :people_per_team
  validates_presence_of :race_datetime, :registration_open, :registration_close
  validates :max_teams, :people_per_team, :numericality => {
    :only_integer => true,
    :greater_than => 0
  }
  validates_uniqueness_of :name
  validates_with RaceValidator

  has_many :registrations
  has_many :teams, -> {distinct}, :through => :registrations

  def full?
    registrations.count == max_teams
  end

  def not_full?
    !full?
  end

  def open?
    now = Time.now
    return false if now < registration_open
    return false if registration_close < now
    true
  end

  class << self
    def find_registerable_races
      Race.all.select do |race|
        race if (race.open? && race.not_full?)
      end
    end
  end

end
