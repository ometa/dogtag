FactoryGirl.define do

  factory :race do
    sequence(:name) { |n| "Race #{n}" }
    registration_open (Time.now - 2.weeks)
    registration_close (Time.now + 2.weeks)
    race_datetime (Time.now + 4.weeks)
    max_teams 2
    people_per_team 3

    factory :closed_race do
      registration_close (Time.now - 1.week)
    end

    trait :with_jsonform do
      jsonform File.read(Rails.root.to_s + '/spec/fixtures/files/valid_jsonform.json')
    end
  end
end
