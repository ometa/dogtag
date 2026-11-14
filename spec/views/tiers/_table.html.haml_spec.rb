require "spec_helper"

describe "tiers/_table", type: :view do
  it "shows tier start times in the race's zone" do
    race = FactoryBot.create(:race, time_zone: "America/Los_Angeles")
    requirement = FactoryBot.create(:payment_requirement, race: race)
    tier = FactoryBot.create(:tier, requirement: requirement, begin_at: Time.utc(2027, 1, 1, 8))

    render partial: "tiers/table", locals: { tiers: [tier], race: race }

    expect(rendered).to include("January 1, 2027 at 12:00 AM PST")
  end
end
