require 'spec_helper'

describe Race do
  let (:valid_team) { FactoryGirl.create :team }
  let (:today) { Time.now.utc }

  describe 'validation' do
    it 'succeeds when all required parameters are present' do
      FactoryGirl.create(:race).should be_valid
    end

    it 'fails without valid datetimes' do
      valid_race_hash = FactoryGirl.attributes_for :race
      dates = [:race_datetime, :registration_open, :registration_close]
      dates.each do |d|
        Race.create(valid_race_hash.merge d => 'abc').should_not be_valid
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
    before do
      @race = FactoryGirl.create :race
      @reg = FactoryGirl.create :team, :race => @race
      @reg.stub(:finalized?).and_return(true)
      @race.teams << @reg
    end

    it 'returns teams with finalized? == true' do
      expect(@race.finalized_teams).to eq [@reg]
    end

    it 'does not return non-finalized teams' do
      reg = FactoryGirl.create :team, :race => @race
      #todo: figure out why the next line is necessary (reverse key lookup?)
      @race.teams << reg
      expect(@race.finalized_teams).to eq [@reg]
    end
  end

  describe '#open_for_registration?' do
    before do
      @race = FactoryGirl.create :race
    end

    it "returns false if now < registration_open" do
      Time.should_receive(:now).and_return @race.registration_open - 1.day
      expect(@race.open_for_registration?).to eq(false)
    end

    it "returns false if registration_close < now" do
      Time.should_receive(:now).and_return @race.registration_close + 1.day
      expect(@race.open_for_registration?).to eq(false)
    end

    it "returns true if open_for_registration? date < today < close date" do
      Time.should_receive(:now).and_return @race.registration_close - 1.day
      expect(@race.open_for_registration?).to eq(true)
    end
  end

  describe '#days_before_close' do
    it 'returns false if registration_close is in the past' do
      closed_race = FactoryGirl.create :closed_race
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
        team = FactoryGirl.create :team, race: @race
        team.stub(:finalized?).and_return true
        #todo: figure out why the next line is necessary (reverse key lookup?)
        @race.teams << team
      end
    end

    it 'returns false if races has less than the maximum finalized teams' do
      expect(@race.full?).to be_false
    end

    it 'returns false if teams are >= the maximum but some are not finalized' do
      @race.teams << FactoryGirl.create(:team)
      expect(@race.full?).to be_false
      @race.teams << FactoryGirl.create(:team)
      expect(@race.full?).to be_false
    end

    it 'returns true if the race has the maximum finalized teams' do
      reg = FactoryGirl.create :team
      reg.stub(:finalized?).and_return true
      @race.teams << reg
      expect(@race.full?).to be_true
    end
  end

  describe '#spots_remaining' do
    before do
      @race = FactoryGirl.create :race
      (@race.max_teams - 1).times do
        reg = FactoryGirl.create(:team, race: @race)
        reg.stub(:finalized?).and_return true
        @race.teams << reg
      end
    end

    it 'returns the correct number of spots remaining' do
      expect(@race.spots_remaining).to eq 1
    end

    it 'returns 0 if there are no spots remaining' do
      reg = FactoryGirl.create :team
      reg.stub(:finalized?).and_return true
      @race.teams << reg
      expect(@race.spots_remaining).to eq 0
    end
  end

  describe '#registerable?' do
    before do
      @race = FactoryGirl.create :race
    end

    it 'returns true if race is open and not full' do
      @race.stub(:open_for_registration?).and_return(true)
      @race.stub(:full?).and_return(false)
      expect(@race.registerable?).to eq(true)
    end

    it 'returns false if race is closed and not full' do
      @race.stub(:open_for_registration?).and_return(false)
      @race.stub(:full?).and_return(false)
      expect(@race.registerable?).to eq(false)
    end

    it 'returns false if race is open and full' do
      @race.stub(:open_for_registration?).and_return(true)
      @race.stub(:full?).and_return(true)
      expect(@race.registerable?).to eq(false)
    end

    it 'returns false if race is closed and full' do
      @race.stub(:open_for_registration?).and_return(false)
      @race.stub(:full?).and_return(true)
    end
  end

  describe '#self.find_registerable_races' do
    it 'returns races where registerable? == true' do
      closed_race = FactoryGirl.create :race
      closed_race.stub(:registerable?).and_return(false)
      open_race = FactoryGirl.create :race
      open_race.stub(:registerable?).and_return(true)
      Race.should_receive(:all).and_return [closed_race, open_race]
      expect(Race.find_registerable_races).to eq([open_race])
    end
  end

  describe '#waitlisted_teams' do
    it 'returns a list of team objects'
    it 'returns them oldest first'
  end

  describe '#self.find_open_races' do
    it "returns races who's registration window is open" do
      closed_race = FactoryGirl.create :race
      closed_race.stub(:open_for_registration?).and_return(false)
      open_race = FactoryGirl.create :race
      open_race.stub(:open_for_registration?).and_return(true)
      Race.should_receive(:all).and_return [closed_race, open_race]
      expect(Race.find_registerable_races).to eq([open_race])
    end
  end

  describe '#waitlist_count' do
    before do
      @race = FactoryGirl.create :race
      (@race.max_teams - 1).times do
        reg = FactoryGirl.create :team, race: @race
        reg.stub(:finalized?).and_return true
        #todo: figure out why the next line is necessary (reverse key lookup?)
        @race.teams << reg
      end
    end

    it 'returns 0 if the race is not full' do
      expect(@race.waitlist_count).to eq(0)
    end

    describe 'when full? == true' do
      before do
        reg = FactoryGirl.create :team, race: @race
        reg.stub(:finalized?).and_return true
        @race.teams << reg
      end

      it 'returns 0 if total teams = finalized_teams' do
        expect(@race.waitlist_count).to eq(0)
      end

      it 'returns the delta between total teams and finalized_teams' do
        reg = FactoryGirl.create :team, race: @race
        @race.teams << reg
        expect(@race.waitlist_count).to eq(1)
      end
    end
  end
end
