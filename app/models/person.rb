class Person < ActiveRecord::Base
  include Wisper.model

  validates_presence_of :first_name, :last_name, :email, :phone, :zipcode
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  validates_format_of :twitter, :with => /\A^@\w+\z/i, :allow_nil => true, :allow_blank => true, :message => 'needs to begin with @ and be one word'
  validates_format_of :zipcode, :with => /\A\d{5}(-\d{4})?\z/, :message => "should be in the form 12345 or 12345-1234"
  validates_format_of :phone, :with => /\A\d{3}-\d{3}-\d{4}\z/, :message => "should be in the form 555-867-5309"
  validates :experience, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0 }
  validates_with PersonValidator, :on => :create

  belongs_to :team

  def self.registered_for_race(race_id)
    race = Race.find race_id
    race.finalized_teams.inject([]) do |total, reg|
      total.concat reg.people.reject{ |person| person.email.downcase =~ /unknown/}
    end
  end
end
