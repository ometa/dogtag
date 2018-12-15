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

  factory :race do
    name { "Race '#{ Faker::Name.unique.name }'" }
    registration_open { (Time.zone.now - 2.weeks) }
    registration_close { (Time.zone.now + 2.weeks) }
    final_edits_close { (Time.zone.now + 3.weeks) }
    race_datetime { (Time.zone.now + 4.weeks) }
    max_teams { 3 }
    people_per_team { 2 }

    factory :full_race do
      after(:create) do |race, evaluator|
        create_list(:finalized_team, race.max_teams, race: race)
      end
    end

    factory :race_with_jsonform do
      transient do
        json_data { File.read(Rails.root.to_s + '/spec/fixtures/files/valid_jsonform.json') }
      end
      jsonform { json_data }

      factory :race_with_jsonform_and_filter_field do
        filter_field { JSON.parse(jsonform)["schema"]["properties"].keys.first(3).join(",") }
      end
    end

    trait :with_classy_data do
      classy_campaign_id { 12345 }
      classy_default_goal { 2000 }
    end

    trait :registration_closed do
      registration_close { (Time.zone.now - 1.week) }
    end

    trait :registration_opens_tomorrow do
      registration_open { (Time.zone.now + 1.day) }
    end

    trait :registration_closing_now do
      registration_close { Time.zone.now }
    end

    trait :in_final_edits_window do
      registration_close { (Time.zone.now - 1.day) }
      final_edits_close { (Time.zone.now + 1.day) }
    end

    trait :after_final_edits_window do
      registration_close { (Time.zone.now - 2.days) }
      final_edits_close { (Time.zone.now - 1.day) }
    end
  end
end
