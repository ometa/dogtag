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
FactoryBot.define do
  factory :person do
    sequence(:first_name) { |n| "Person#{n}" }
    sequence(:last_name) { |n| "Member#{n}" }
    sequence(:email) { |n| "person#{n}@example.com" }
    sequence(:phone) { |n| "555-#{100 + n}-#{1000 + n}" }
    experience { 3 }
    zipcode { '12345' }
    association :team, strategy: :build
  end
end
