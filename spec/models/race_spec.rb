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
require 'spec_helper'

describe Race do
  let(:today) { Time.zone.now }

  describe 'scopes' do
    describe 'past'
    describe 'current'
  end

  describe 'validation' do
    it 'succeeds when all required parameters are present' do
      expect(FactoryBot.build(:race)).to be_valid
    end

    it 'fails without valid datetimes' do
      valid_race_hash = FactoryBot.attributes_for :race
      dates = [:race_datetime, :registration_open, :registration_close, :final_edits_close]
      dates.each do |d|
        expect(Race.create(valid_race_hash.merge d => 'abc')).not_to be_valid
      end
    end

    context 'registration_open is after registration_close' do
      let(:race) do
        FactoryBot.build :race, race_datetime: today + 4.weeks,
          registration_open: (today + 3.weeks), registration_close: (today + 1.week), final_edits_close: (today + 3.weeks)
      end

      it 'fails validation' do
        expect(race).to be_invalid
        expect(race.errors.messages[:registration_open]).to include 'must come before registration_close'
      end
    end

    context 'final_edits_close is after race_datetime' do
      let(:race) do
        FactoryBot.build :race, race_datetime: today + 4.weeks,
          registration_open: (today + 1.week), registration_close: (today + 2.weeks), final_edits_close: (today + 5.weeks)
      end

      it 'fails validation' do
        expect(race).to be_invalid
        expect(race.errors.messages[:final_edits_close]).to include 'must come before race_datetime'
      end
    end

    context 'registration_close is after final_edits_close' do
      let(:race) do
        FactoryBot.build :race, race_datetime: today + 4.weeks,
          registration_open: (today + 1.week), registration_close: (today + 3.weeks), final_edits_close: (today + 2.weeks)
      end

      it 'fails validation' do
        expect(race).to be_invalid
        expect(race.errors.messages[:registration_close]).to include 'must come before final_edits_close'
      end
    end
  end

  describe '#question_fields' do
    context 'when there is no jsonform data' do
      let(:race) { FactoryBot.build :race }

      it 'returns empty array' do
        expect(race.question_fields).to eq([])
      end
    end

    context 'when there is jsonform data' do
      let(:race) { FactoryBot.build :race_with_jsonform }
      let(:keys) do
        file = File.read(Rails.root.to_s + '/spec/fixtures/files/valid_jsonform.json')
        JSON.parse(file)['schema']['properties'].keys
      end

      it 'returns an enumerable of the keys stored in the jsonform schema' do
        expect(race.question_fields).to eq(keys)
      end
    end

    context 'when json is malformed' do
      let(:race) { FactoryBot.build :race_with_jsonform, json_data: '{' }

      it 'returns empty array' do
        expect(race.question_fields).to eq([])
      end
    end
  end

  describe '#filter_field_array' do
    context 'when filter_field is nil' do
      let(:race) { FactoryBot.build :race, filter_field: nil }

      it 'returns empty array' do
        expect(race.filter_field_array).to eq([])
      end
    end

    context 'when filter_field is blank' do
      let(:race) { FactoryBot.build :race, filter_field: '' }

      it 'returns empty array' do
        expect(race.filter_field_array).to eq([])
      end
    end

    context 'when filter_field contains comma-separated values' do
      let(:race) { FactoryBot.build :race, filter_field: 'field1,field2,field3' }

      it 'returns array of values' do
        expect(race.filter_field_array).to eq(['field1', 'field2', 'field3'])
      end
    end
  end


  describe '#in_final_edits_window?' do
    context "registration is closed and final edit window close is in the future" do
      let(:race) { FactoryBot.build :race, :in_final_edits_window }
      it "returns true" do
        expect(race.in_final_edits_window?).to be true
      end
    end

    context "registration is still open" do
      let(:race) { FactoryBot.build :race }
      it "returns false" do
        expect(race.in_final_edits_window?).to be false
      end
    end
  end

  describe '#registration_over?' do
    context 'registration close is in the future' do
      let(:race) { FactoryBot.build :race }
      it 'returns false' do
        expect(race.registration_over?).to be false
      end
    end
    context 'registration close is right now' do
      let(:race) { FactoryBot.build :race, :registration_closing_now }
      it 'returns true' do
        expect(race.registration_over?).to be true
      end
    end
    context 'registration close is in the past' do
      let(:race) { FactoryBot.build :race, :registration_closed }
      it 'returns true' do
        expect(race.registration_over?).to be true
      end
    end
  end

  describe '#enabled_requirements' do
    before do
      @race = FactoryBot.create :race
      @req = FactoryBot.create :enabled_payment_requirement, :race => @race
    end

    it 'returns requirements where enabled? == true' do
      expect(@race.enabled_requirements).to eq [@req]
    end

    it 'does not return disabled requirements' do
      FactoryBot.create :payment_requirement, :race => @race
      expect(@race.enabled_requirements).to eq [@req]
    end
  end

  describe '#finalized_teams' do
    let(:team)        { FactoryBot.create :finalized_team }
    let(:race)        { team.race }
    let(:unfinalized) { FactoryBot.create :team, race: race }

    it 'returns finalized teams, not unfinalized teams' do
      expect(race.finalized_teams).to eq [team]
    end
  end

  describe '#not_yet_open?' do
    context "registration opens in the future" do
      let(:race) { FactoryBot.build :race, :registration_opens_tomorrow }
      it "returns true" do
        expect(race.not_yet_open?).to be true
      end
    end

    context "registration opens in present or past" do
      let(:race) { FactoryBot.build :race, :registration_closed }
      it "returns false" do
        expect(race.not_yet_open?).to be false
      end
    end
  end

  describe '#open_for_registration?' do
    context "race is not yet open" do
      let(:race) { FactoryBot.build :race, :registration_opens_tomorrow }
      it "returns false" do
        expect(race.open_for_registration?).to eq(false)
      end
    end

    context "race registration is closed" do
      let(:race) { FactoryBot.build :race, :registration_closed }
      it "returns false" do
        expect(race.open_for_registration?).to eq(false)
      end
    end

    context "race registration is open" do
      let(:race) { FactoryBot.build :race }
      it "returns true" do
        expect(race.open_for_registration?).to eq(true)
      end
    end
  end

  describe "over?" do
    context "when the race date is in the past" do
      let(:now) { Time.zone.now }
      let(:race) do
        FactoryBot.build :race, race_datetime: (now - 1.day),
          final_edits_close: (now - 2.days), registration_close: (now - 3.days)
      end

      it "returns false" do
        expect(race.over?).to be true
      end
    end

    context "when the race date is in the future" do
      let(:race) { FactoryBot.create :race }
      it "returns false" do
        expect(race.over?).to be false
      end
    end

    context 'race is right now' do
      it 'returns false' do
        Timecop.freeze do
          race = FactoryBot.build :race, race_datetime: Time.zone.now
          expect(race.over?).to be false
        end
      end
    end
  end

  describe '#days_before_close' do
    it 'returns false if registration_close is in the past' do
      closed_race = FactoryBot.create :race, :registration_closed
      expect(closed_race.days_before_close).to eq(false)
    end

    it 'returns the time between now and registration_close' do
      double(Time.zone.now) { today }
      race = FactoryBot.create :race, :race_datetime => (today + 4.weeks), :registration_open => (today - 2.weeks), :registration_close => (today + 2.weeks)
      expect(race.days_before_close).to eq(2.weeks.to_i)
    end
  end

  describe '#full?' do
    before do
      @race = FactoryBot.create :race
      (@race.max_teams - 1).times do
        FactoryBot.create :finalized_team, race: @race
      end
    end

    it 'returns false if races has less than the maximum finalized teams' do
      expect(@race.full?).to be false
    end

    it 'returns false if teams are >= the maximum but some are not finalized' do
      @race.teams << FactoryBot.create(:team)
      expect(@race.full?).to be false
      @race.teams << FactoryBot.create(:team)
      expect(@race.full?).to be false
    end

    it 'returns true if the race has the maximum finalized teams' do
      FactoryBot.create :finalized_team, race: @race
      expect(@race.full?).to be true
    end
  end

  describe '#spots_remaining' do
    before do
      @race = FactoryBot.create :race
      (@race.max_teams - 1).times do
        FactoryBot.create :finalized_team, race: @race
      end
    end

    it 'returns the correct number of spots remaining' do
      expect(@race.spots_remaining).to eq 1
    end

    it 'returns 0 if there are no spots remaining' do
      FactoryBot.create :finalized_team, race: @race
      expect(@race.spots_remaining).to eq 0
    end
  end

  describe '#registerable?' do
    before do
      @race = FactoryBot.create :race
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

  describe '#waitlisted_teams' do
    context 'when race is not full' do
      let(:race) { FactoryBot.create :race }

      it 'returns empty array' do
        FactoryBot.create :team, race: race
        expect(race.waitlisted_teams).to eq([])
      end
    end

    context 'when race is full' do
      let(:race) { FactoryBot.create :full_race }

      it 'returns a list of team objects' do
        waitlisted = FactoryBot.create :team, race: race
        expect(race.waitlisted_teams).to eq([waitlisted])
      end

      it 'returns them oldest first' do
        newer_team = FactoryBot.create :team, race: race, created_at: Time.zone.now
        older_team = FactoryBot.create :team, race: race, created_at: 1.day.ago

        expect(race.waitlisted_teams).to eq([older_team, newer_team])
      end
    end
  end

  describe '#stats' do

    context 'when race has no registered teams' do
      let(:race) { FactoryBot.create :race }
      it 'returns hash showing zero' do
        expect(race.stats).to eq({"money_raised" => 0})
      end
    end

    context 'when race has teams that paid money' do
      let(:cr) { FactoryBot.create :completed_requirement, :with_metadata }
      it 'returns hash showing zero' do
        expect(cr.team.race.stats).to eq({"money_raised" => 7000})
      end
    end
  end

  describe '#waitlist_count' do
    let(:race) { FactoryBot.create :race }

    it 'returns 0 if the race is not full' do
      expect(race.waitlist_count).to eq(0)
    end

    context 'when the race is full' do
      before do
        race.max_teams.times { FactoryBot.create :finalized_team, race: race }
      end

      context "and total teams = max teams" do
        it "returns 0" do
          expect(race.waitlist_count).to eq(0)
        end
      end

      context "and total teams > max teams" do
        it 'returns the delta between total teams and max teams' do
          FactoryBot.create :team, race: race
          expect(race.waitlist_count).to eq(1)
        end
      end
    end
  end
end
