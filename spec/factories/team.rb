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

  factory :team do
    sequence(:name)    { |n| "Team #{n}" }
    description        { "omg! #{name} is the best team evar." }
    sequence(:twitter) { |n| "@twitter#{n}" }
    experience { 5 }

    user
    race

    factory :finalized_team do
      after(:create) do |team|
        create_list(:person, team.race.people_per_team, team: team)
        team.finalize
      end
    end

    factory :team_with_jsonform do
      jsonform { File.read(Rails.root.to_s + '/spec/fixtures/files/valid_team_jsonform.json') }
      race factory: :race_with_jsonform
    end

    trait :with_classy_id do
      classy_id { 123456 }
    end

    # classy_id is a prerequisite
    trait :with_classy_fundraising_page do
      classy_id { 123456 }
      classy_fundraiser_page_id { 42 }
    end

    trait :with_people do
      transient do
        people_count { race.people_per_team - 1 }
      end
      after(:create) do |team, evaluator|
        create_list(:person, evaluator.people_count, team: team)
      end
    end

    trait :with_enough_people do
      after(:create) do |team|
        create_list(:person, team.race.people_per_team, team: team)
      end
    end
  end
end
