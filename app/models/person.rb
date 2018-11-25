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
class Person < ApplicationRecord
  validates_presence_of :first_name, :last_name, :email, :phone, :zipcode
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  validates_format_of :twitter, :with => /\A^@\w+\z/i, :allow_nil => true, :allow_blank => true, :message => 'needs to begin with @ and be one word'
  validates_format_of :zipcode, :with => /\A\d{5}(-\d{4})?\z/, :message => "should be in the form 12345 or 12345-1234"
  validates_format_of :phone, :with => /\A\d{3}-\d{3}-\d{4}\z/, :message => "should be in the form 555-867-5309"
  validates :experience, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0 }
  validates_with PersonValidator, :on => :create

  include Wisper.model

  belongs_to :team

  include ActionView::Helpers::NumberHelper
  def phone=(val)
    super(number_to_phone(val, area_code: false, delimiter: '-'))
  end

  def self.registered_for_race(race_id)
    race = Race.find race_id
    race.finalized_teams.inject([]) do |total, reg|
      total.concat(reg.people.reject{ |person| person.email.downcase =~ /unknown/})
    end
  end
end
