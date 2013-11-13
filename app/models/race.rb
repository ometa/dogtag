class Race < ActiveRecord::Base
  validates_presence_of :name, :race_datetime, :max_teams, :racers_per_team
  validates :max_teams, :racers_per_team, :numericality => {
    :only_integer => true,
    :greater_than => 0
  }
  validates_uniqueness_of :name
  validates_with RaceValidator

  has_many :teams
end
