require 'spec_helper'

describe Race do
  let(:today) { Time.now.utc }

  describe 'scopes' do
    describe 'past'
    describe 'current'
  end

  describe 'validation' do
    it 'succeeds when all required parameters are present' do
      expect(FactoryGirl.create(:race)).to be_valid
    end

    it 'fails without valid datetimes' do
      valid_race_hash = FactoryGirl.attributes_for :race
      dates = [:race_datetime, :registration_open, :registration_close]
      dates.each do |d|
        expect(Race.create(valid_race_hash.merge d => 'abc')).not_to be_valid
      end
    end

    it 'fails when registration close and open dates are the same' do
      race = FactoryGirl.build :race, :race_datetime => today,
        :registration_open => (today - 1.week), :registration_close => (today - 1.week)
      expect(race).to be_invalid
      expect(race.errors.messages[:registration_open]).to include 'must come before registration_close'
    end

    it 'fails when registration close date is before registration open date' do
      race = FactoryGirl.build :race, :race_datetime => today,
        :registration_open => (today - 1.week), :registration_close => (today - 2.weeks)
      expect(race).to be_invalid
      expect(race.errors.messages[:registration_open]).to include 'must come before registration_close'
    end

    it 'fails when registration open and close dates are not before the race_datetime' do
      race = FactoryGirl.build :race, :race_datetime => today,
        :registration_open => (today + 1.week), :registration_close => (today + 2.weeks)
      expect(race).to be_invalid
      expect(race.errors.messages[:registration_open]).to include 'must come before race_datetime'
      expect(race.errors.messages[:registration_close]).to include 'must come before race_datetime'
    end
  end

  describe '#question_fields' do
    context 'when there is no jsonform data' do
      let(:race) { FactoryGirl.build :race }

      it 'returns empty array' do
        expect(race.question_fields).to eq([])
      end
    end

    context 'when there is jsonform data' do
      let(:race) { FactoryGirl.build :race_with_jsonform }
      let(:keys) do
        file = File.read(Rails.root.to_s + '/spec/fixtures/files/valid_jsonform.json')
        JSON.parse(file)['schema']['properties'].keys
      end

      it 'returns an enumerable of the keys stored in the jsonform schema' do
        expect(race.question_fields).to eq(keys)
      end
    end

    context 'when json is malformed' do
      let(:race) { FactoryGirl.build :race_with_jsonform, json_data: '{' }

      it 'returns empty array' do
        expect(race.question_fields).to eq([])
      end
    end
  end

  # TODO: this has to do with which jsonform question fields to show in the registrations
  # rendering.  need confirmation & testing.
  describe '#filter_field_array' do
    context 'when filter_field is nil' do
      it 'returns empty array'
    end
    context 'when filter_field is blank' do
      it 'returns empty array'
    end
    context 'when filter_field contains comma-separated values' do
      it 'returns array of values'
    end
  end

  describe '#over?' do
    context 'race is in the future' do
      it 'returns false'
    end
    context 'race is right now' do
      it 'returns false'
    end
    context 'race is in the past' do
      it 'returns true'
    end
  end

  describe '#registration_over?' do
    context 'registration close is in the future' do
      let(:race) { FactoryGirl.create :race }
      it 'returns false' do
        expect(race.registration_over?).to be false
      end
    end
    context 'registration close is right now' do
      let(:race) { FactoryGirl.create :race, :registration_closing_now }
      it 'returns true' do
        expect(race.registration_over?).to be true
      end
    end
    context 'registration close is in the past' do
      let(:race) { FactoryGirl.create :race, :registration_closed }
      it 'returns true' do
        expect(race.registration_over?).to be true
      end
    end
  end

  describe '#enabled_requirements' do
    before do
      @race = FactoryGirl.create :race
      @req = FactoryGirl.create :enabled_payment_requirement, :race => @race
    end

    it 'returns requirements where enabled? == true' do
      expect(@race.enabled_requirements).to eq [@req]
    end

    it 'does not return disabled requirements' do
      FactoryGirl.create :payment_requirement, :race => @race
      expect(@race.enabled_requirements).to eq [@req]
    end
  end

  describe '#finalized_teams' do
    let(:team)        { FactoryGirl.create :finalized_team }
    let(:race)        { team.race }
    let(:unfinalized) { FactoryGirl.create :team, race: race }

    it 'returns finalized teams, not unfinalized teams' do
      expect(race.finalized_teams).to eq [team]
    end
  end

  describe '#open_for_registration?' do
    context "race is not yet open" do
      let(:race) { FactoryGirl.create :race, :registration_opens_tomorrow }
      it "returns false" do
        expect(race.open_for_registration?).to eq(false)
      end
    end

    context "race registration is closed" do
      let(:race) { FactoryGirl.create :race, :registration_closed }
      it "returns false" do
        expect(race.open_for_registration?).to eq(false)
      end
    end

    context "race registration is open" do
      let(:race) { FactoryGirl.create :race }
      it "returns true" do
        expect(race.open_for_registration?).to eq(true)
      end
    end
  end

  describe "over?" do
    context "when the race date is in the past" do
      let(:race) { FactoryGirl.create :ended_race }
      it "returns false" do
        expect(race.over?).to be true
      end
    end

    context "when the race date is in the future" do
      let(:race) { FactoryGirl.create :race }
      it "returns false" do
        expect(race.over?).to be false
      end
    end
  end

  describe '#days_before_close' do
    it 'returns false if registration_close is in the past' do
      closed_race = FactoryGirl.create :race, :registration_closed
      expect(closed_race.days_before_close).to eq(false)
    end

    it 'returns the time between now and registration_close' do
      double(Time.now) { today }
      race = FactoryGirl.create :race, :race_datetime => (today + 4.weeks), :registration_open => (today - 2.weeks), :registration_close => (today + 2.weeks)
      expect(race.days_before_close).to eq(2.weeks.to_i)
    end
  end

  describe '#full?' do
    before do
      @race = FactoryGirl.create :race
      (@race.max_teams - 1).times do
        FactoryGirl.create :finalized_team, race: @race
      end
    end

    it 'returns false if races has less than the maximum finalized teams' do
      expect(@race.full?).to be false
    end

    it 'returns false if teams are >= the maximum but some are not finalized' do
      @race.teams << FactoryGirl.create(:team)
      expect(@race.full?).to be false
      @race.teams << FactoryGirl.create(:team)
      expect(@race.full?).to be false
    end

    it 'returns true if the race has the maximum finalized teams' do
      FactoryGirl.create :finalized_team, race: @race
      expect(@race.full?).to be true
    end
  end

  describe '#spots_remaining' do
    before do
      @race = FactoryGirl.create :race
      (@race.max_teams - 1).times do
        FactoryGirl.create :finalized_team, race: @race
      end
    end

    it 'returns the correct number of spots remaining' do
      expect(@race.spots_remaining).to eq 1
    end

    it 'returns 0 if there are no spots remaining' do
      FactoryGirl.create :finalized_team, race: @race
      expect(@race.spots_remaining).to eq 0
    end
  end

  describe '#registerable?' do
    before do
      @race = FactoryGirl.create :race
    end

    it 'returns true if race is open and not full' do
      allow(@race).to receive(:open_for_registration?).and_return(true)
      allow(@race).to receive(:full?).and_return(false)
      expect(@race.registerable?).to eq(true)
    end

    it 'returns false if race is closed and not full' do
      allow(@race).to receive(:open_for_registration?).and_return(false)
      allow(@race).to receive(:full?).and_return(false)
      expect(@race.registerable?).to eq(false)
    end

    it 'returns false if race is open and full' do
      allow(@race).to receive(:open_for_registration?).and_return(true)
      allow(@race).to receive(:full?).and_return(true)
      expect(@race.registerable?).to eq(false)
    end

    it 'returns false if race is closed and full' do
      allow(@race).to receive(:open_for_registration?).and_return(false)
      allow(@race).to receive(:full?).and_return(true)
    end
  end

  describe 'self#find_registerable_races' do
    it 'returns races that are open and have spaces left' do
      FactoryGirl.create :race, :registration_closed
      FactoryGirl.create :full_race
      open_race = FactoryGirl.create :race
      expect(Race.find_registerable_races).to eq([open_race])
    end
  end

  describe 'self#find_open_races' do
    it "only returns races where registration is open" do
      FactoryGirl.create :race, :registration_closed
      open_race = FactoryGirl.create :race
      expect(Race.find_open_races).to eq([open_race])
    end
  end

  describe '#waitlisted_teams' do
    it 'returns a list of team objects'
    it 'returns them oldest first'
  end

  describe '#stats' do

    context 'when race has no registered teams' do
      let(:race) { FactoryGirl.create :race }
      it 'returns hash showing zero' do
        expect(race.stats).to eq({"money_raised" => 0})
      end
    end

    context 'when race has teams that paid money' do
      let(:cr) { FactoryGirl.create :completed_requirement, :with_metadata }
      it 'returns hash showing zero' do
        expect(cr.team.race.stats).to eq({"money_raised" => 7000})
      end
    end
  end

  describe '#waitlist_count' do
    let(:race) { FactoryGirl.create :race }

    it 'returns 0 if the race is not full' do
      expect(race.waitlist_count).to eq(0)
    end

    context 'when the race is full' do
      before do
        race.max_teams.times { FactoryGirl.create :finalized_team, race: race }
      end

      context "and total teams = max teams" do
        it "returns 0" do
          expect(race.waitlist_count).to eq(0)
        end
      end

      context "and total teams > max teams" do
        it 'returns the delta between total teams and max teams' do
          FactoryGirl.create :team, race: race
          expect(race.waitlist_count).to eq(1)
        end
      end
    end
  end
end
