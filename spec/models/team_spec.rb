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

describe Team do

  describe 'scopes' do
    describe 'all_finalized' do
      let!(:team) { FactoryBot.create :finalized_team }

      it 'returns only finalized teams' do
        FactoryBot.create :team
        expect(Team.all_finalized).to eq([team])
      end
    end

    describe 'all_unfinalized' do
      let!(:team) { FactoryBot.create :finalized_team }

      it 'returns only unfinalized teams' do
        unfinalized = FactoryBot.create :team
        expect(Team.all_unfinalized).to eq([unfinalized])
      end
    end

    describe 'belonging_to' do
      let!(:team) { FactoryBot.create :team }

      it 'returns teams created by a specific user' do
        expect(Team.belonging_to(team.user_id)).to eq([team])
      end

      it 'returns empty if not a match' do
        expect(Team.belonging_to(team.user_id + 1)).to be_empty
      end
    end
  end

  describe 'validation' do
    let(:race) { FactoryBot.create :race }
    let(:team) { FactoryBot.create :team }

    context 'succeeds' do
      it 'when all required parameters are present' do
        expect(team).to be_valid
      end

      it 'when a race is open' do
        expect(FactoryBot.build :team, race: race).to be_valid
      end
    end

    context 'fails' do
      it 'when the same team name registers for a race more than once' do
        expect(FactoryBot.create :team, name: 'mushfaces', race: race).to be_valid
        expect(FactoryBot.build :team, name: 'mushfaces', race: race).to be_invalid
      end
    end

    it 'a team can be named the same in different races' do
      race2 = FactoryBot.create :race
      expect(FactoryBot.create :team, name: 'mushfaces', race: race).to be_valid
      expect(FactoryBot.build :team, name: 'mushfaces', race: race2).to be_valid
    end
  end

  describe '.finalize' do

    context 'called on a finalized team' do
      let(:team) { FactoryBot.create :finalized_team }

      it 'returns nil' do
        expect(team.finalize).to be_nil
      end
    end

    context 'called on an unfinalized team that does not meet requirements' do
      let(:team) { FactoryBot.create :team, :with_people }

      it 'returns nil' do
        expect(team.finalize).to be_nil
      end
    end

    context 'not yet finalized and meets all requirements' do

      let(:team) { FactoryBot.create :team, :with_enough_people }

      it 'sets finalized boolean and notified_at in the db' do
        team.finalize
        record = Team.find(team.id)
        expect(record.notified_at).to_not be_nil
        expect(record.finalized).to be true
      end

      context 'team number assignments' do
        it 'assigns the next available team number' do
          team.finalize
          team.reload
          expect(team.assigned_team_number).to eq(1)
        end

        context 'if the team already has an assigned team number' do
          it 'uses the same number' do
            team.finalize
            team.unfinalize(true)
            team.finalize
            team.reload
            expect(team.assigned_team_number).to eq(1)
          end
        end

        context 'when there are teams that used to be finalized and now are not' do
          it 'skips over the formerly assigned team number to a new one' do
            t = FactoryBot.create :finalized_team, race: team.race
            t.unfinalize(true)
            t.reload
            expect(t.finalized).to be_falsey

            team.finalize
            team.reload
            expect(team.assigned_team_number).to eq(2)
          end
        end
      end

      it 'Queues up an email to the user and logs status' do
        expect(Rails.logger).to receive(:info).with("Finalized Team: #{team.name} (id: #{team.id})")
        expect(Workers::TeamFinalizer).to receive(:perform_async).with({'team_id' => team.id})
        team.finalize
      end
    end
  end

  describe '.unfinalize' do

    context 'when passed force=true with a finalized team' do
      let(:team) { FactoryBot.create :finalized_team }
      it 'unfinalizes the team' do
        team.unfinalize(true)
        record = Team.find(team.id)
        expect(record.notified_at).to be_nil
        expect(record.finalized).to be_nil
      end
    end

    context 'called on a unfinalized team' do
      let(:team) { FactoryBot.create :team, :with_enough_people }
      it 'returns nil' do
        expect(team.unfinalize).to be_nil
      end
    end

    context 'called on a finalized team that meets requirements' do
      let(:team) { FactoryBot.create :finalized_team }
      it 'returns nil' do
        expect(team.unfinalize).to be_nil
      end
    end

    context 'called on a finalized team that no longer meets requirements' do
      let(:team) do
        _t = FactoryBot.create :finalized_team
        Person.delete(_t.people.first.id)
        _t
      end

      it 'unsets finalized and notified_at in the db' do
        team.unfinalize
        record = Team.find(team.id)
        expect(record.notified_at).to be_nil
        expect(record.finalized).to be_nil
      end

      it "leaves the 'assigned_team_number' field alone (immutable)" do
        num = team.assigned_team_number
        team.unfinalize
        team.reload
        expect(team.assigned_team_number).to eq(num)
      end
    end
  end

  describe '.unfinalized' do
    it 'returns true when team is unfinalized 'do
      team = FactoryBot.create :team
      expect(team.unfinalized).to be_truthy
    end

    it 'returns false when team is finalized 'do
      team = FactoryBot.create :finalized_team
      expect(team.unfinalized).to be_falsey
    end
  end

  describe '.finalized' do
    it 'returns true when team is finalized 'do
      team = FactoryBot.create :finalized_team
      expect(team.finalized).to be_truthy
    end

    it 'returns false when team is unfinalized 'do
      team = FactoryBot.create :team
      expect(team.finalized).to be_falsey
    end
  end

  describe '.person_experience' do

    context "when there are no people on the team" do
      let(:team) { FactoryBot.create :team }
      it "returns 0" do
        expect(team.person_experience).to eq(0)
      end
    end

    context "when there are people on the team" do
      let(:team) { FactoryBot.create :team, :with_enough_people }
      it "sums their total experience" do
        expect(team.person_experience).to eq(6)
      end
    end
  end

  describe '.jsonform_value' do
    let(:key) { "racer-type" }

    context 'when team has no jsonform data' do
      let(:team) { FactoryBot.create :team }
      it 'returns nil' do
        expect(team.jsonform_value(key)).to be_nil
      end
    end

    context "when team's jsonform has the value" do
      let(:team) { FactoryBot.create :team_with_jsonform }
      it 'returns the value' do
        expect(team.jsonform_value(key)).to eq("Racer")
      end
    end

    context 'when team does not have jsonform data for a certain key' do
      let(:team) { FactoryBot.create :team_with_jsonform }
      it 'returns nil' do
        expect(team.jsonform_value("foo")).to be_nil
      end
    end
  end

  describe '#completed_questions?' do

    context 'race has no jsonform' do
      let(:race) { FactoryBot.create :race }
      let(:team) { FactoryBot.create :team, race: race }
      it "returns true" do
        expect(team.completed_questions?).to be true
      end
    end

    context 'race has a jsonform' do

      context 'team has jsonform data' do
        let(:team) { FactoryBot.create :team_with_jsonform }

        it "returns true" do
          expect(team.completed_questions?).to be true
        end
      end

      context 'team has no jsonform data' do
        let(:race) { FactoryBot.create :race_with_jsonform }
        let(:team) { FactoryBot.create :team, race: race }

        it "returns false" do
          expect(team.completed_questions?).to be false
        end
      end
    end
  end

  describe ".money_paid_in_cents" do
    let(:team) { FactoryBot.create :team }

    it "returns 0 when no completed requirements" do
      expect(team.money_paid_in_cents).to eq(0)
    end

    it "reports the amount of money a team has paid according to its completed requirements" do
      FactoryBot.create :completed_requirement, :with_metadata, team: team, hash: { 'amount' => '5000' }
      FactoryBot.create :completed_requirement, :with_metadata, team: team, hash: { 'amount' => '2500' }
      expect(team.money_paid_in_cents).to eq(7500)
    end
  end

  describe '#export' do
    let(:race) { FactoryBot.create :race }
    let!(:team) { FactoryBot.create :team, :with_enough_people, race: race }

    it 'sets the correct columns' do
      result = Team.export(race.id)
      header = result.first

      # Basic columns
      expect(header).to include('finalized', 'number', 'name', 'experience', 'description')

      # User columns
      expect(header).to include('user_first_name', 'user_last_name', 'user_email', 'user_phone', 'user_stripe_customer_id')

      # People columns (dawg_0_*, dawg_1_*, etc. based on people_per_team)
      race.people_per_team.times do |i|
        expect(header).to include("dawg_#{i}_first_name", "dawg_#{i}_last_name", "dawg_#{i}_email", "dawg_#{i}_phone", "dawg_#{i}_twitter", "dawg_#{i}_experience")
      end
    end

    it 'returns a multi-dimensional array of teams' do
      result = Team.export(race.id)

      expect(result).to be_an(Array)
      expect(result.size).to eq(2) # header + 1 team

      team_row = result.last
      expect(team_row).to include(team.name)
      expect(team_row).to include(team.description)
    end

    context 'with finalized option' do
      let!(:unfinalized_team) { FactoryBot.create :team, race: race }
      let!(:finalized_team) { FactoryBot.create :finalized_team, race: race }

      it 'returns only finalized teams when finalized: true' do
        result = Team.export(race.id, finalized: true)
        expect(result.size).to eq(2) # header + 1 finalized team
        expect(result.last).to include(finalized_team.name)
      end
    end
  end

  describe '#percent_complete' do

    let(:answer) do
      possible = team.race.people_per_team + team.race.requirements.size
      ((team.people.size + team.completed_requirements.size) * 100 ) / possible
    end
    shared_examples "returns correct percentage" do
      it "returns correct percentage" do
        expect(team.percent_complete).to eq(answer)
      end
    end

    context "when no people have been added and payment requirements are not satisfied" do
      let(:req)  { FactoryBot.create :payment_requirement }
      let(:team) { FactoryBot.create :team, race: req.race}

      include_examples "returns correct percentage"
    end

    context "when no people have been added and payment requirements are satisfied" do
      let(:req)  { FactoryBot.create :payment_requirement_with_tier }
      let(:team) { FactoryBot.create :team, race: req.race }
      let!(:cr)  { FactoryBot.create :completed_requirement, requirement: req, team: team }

      include_examples "returns correct percentage"
    end

    context "when some people have been added and payment requirements are not satisfied" do
      let(:req)  { FactoryBot.create :payment_requirement_with_tier }
      let(:team) { FactoryBot.create :team, :with_people, race: req.race }

      include_examples "returns correct percentage"
    end

    context "when some people have been added and payment requirements are satisfied" do
      let(:team) { FactoryBot.create :team, :with_people }
      let(:req)  { FactoryBot.create :payment_requirement_with_tier, race: team.race }
      let!(:cr)  { FactoryBot.create :completed_requirement, requirement: req, team: team }

      include_examples "returns correct percentage"
    end

    context "when all people have been added and payment requirements are satisfied" do
      let(:team) { FactoryBot.create :team, :with_enough_people }
      let(:req)  { FactoryBot.create :payment_requirement_with_tier, race: team.race }
      let!(:cr)  { FactoryBot.create :completed_requirement, requirement: req, team: team }

      include_examples "returns correct percentage"
    end

    context 'when race has some jsonschema' do
      context 'and team does not' do
        let(:race) { FactoryBot.create :race_with_jsonform }
        let(:team) { FactoryBot.create :team, :with_people, race: race }

        it "includes jsonform in total but not in completed" do
          # total = people_per_team (2) + requirements (0) + jsonform (1) = 3
          # var = people (1) + requirements (0) + no team jsonform (0) = 1
          # percent = (1 * 100) / 3 = 33
          expect(team.percent_complete).to eq(33)
        end
      end

      context 'and team does also' do
        let(:team) { FactoryBot.create :team_with_jsonform, :with_people }

        it "includes jsonform in both total and completed" do
          # total = people_per_team (2) + requirements (0) + jsonform (1) = 3
          # var = people (1) + requirements (0) + team jsonform (1) = 2
          # percent = (2 * 100) / 3 = 66
          expect(team.percent_complete).to eq(66)
        end
      end
    end
  end

  describe '#needs_people?' do
    let(:race) { FactoryBot.create :race }
    let(:reg)  { FactoryBot.create :team, :with_people, :race => race }

    it 'returns true if there are less than race.people_per_team people' do
      expect(reg.needs_people?).to be true
    end

    it 'returns false if there are race.people_per_team people' do
      reg.people << FactoryBot.create(:person)
      expect(reg.needs_people?).to be false
    end
  end

  describe '#waitlist_position' do
    context 'when race is not full' do
      let(:team) { FactoryBot.create :team }

      it 'returns false' do
        expect(team.waitlist_position).to be false
      end
    end

    context 'when team is finalized' do
      let(:team) { FactoryBot.create :finalized_team }

      it 'returns false' do
        allow(team.race).to receive(:not_full?).and_return(false)
        expect(team.waitlist_position).to be false
      end
    end

    context 'when race is full and team is not finalized' do
      let(:race) { FactoryBot.create :full_race }

      it 'returns our position on the waitlist by created_at date' do
        first_team = FactoryBot.create :team, race: race, created_at: 1.day.ago
        second_team = FactoryBot.create :team, race: race, created_at: 1.hour.ago
        third_team = FactoryBot.create :team, race: race, created_at: Time.zone.now

        expect(first_team.waitlist_position).to eq(1)
        expect(second_team.waitlist_position).to eq(2)
        expect(third_team.waitlist_position).to eq(3)
      end
    end
  end

  describe '#is_full?' do
    it 'should be the opposite of #needs_people?' do
      reg = FactoryBot.create :team
      allow(reg).to receive(:needs_people?).and_return false
      expect(reg.is_full?).to eq(true)
    end
  end

  describe '#meets_finalization_requirements?' do
    before do
      @reg = FactoryBot.create :team
    end

    it "returns true if it doesn't need people, and all requirements are met" do
      allow(@reg).to receive(:completed_all_requirements?).and_return true
      allow(@reg).to receive(:is_full?).and_return true
      expect(@reg.meets_finalization_requirements?).to be_truthy
    end

    it "returns false if it needs people, and all requirements are met" do
      allow(@reg).to receive(:completed_all_requirements?).and_return true
      allow(@reg).to receive(:is_full?).and_return false
      expect(@reg.meets_finalization_requirements?).to be_falsey
    end

    it "returns false if it doesn't need people, and all requirements are NOT met" do
      allow(@reg).to receive(:completed_all_requirements?).and_return false
      allow(@reg).to receive(:is_full?).and_return true
      expect(@reg.meets_finalization_requirements?).to be_falsey
    end

    it "returns false if it needs people, and all requirements are NOT met" do
      allow(@reg).to receive(:completed_all_requirements?).and_return false
      allow(@reg).to receive(:is_full?).and_return false
      expect(@reg.meets_finalization_requirements?).to be_falsey
    end
  end

  describe '#completed_all_requirements?' do
    before do
      @reg = FactoryBot.create :team
      @race = @reg.race
      req = FactoryBot.create :enabled_payment_requirement, :race => @race
      FactoryBot.create :completed_requirement, :requirement => req, :team => @reg
    end

    it 'returns true when a race has no requirements' do
      reg = FactoryBot.create :team
      expect(reg.completed_all_requirements?).to eq(true)
    end

    it 'returns true when all enabled requirements are completed' do
      expect(@reg.completed_all_requirements?).to eq(true)
    end

    it 'return false if any enabled requirements are not completed' do
      FactoryBot.create :enabled_payment_requirement, :race => @race
      expect(@reg.completed_all_requirements?).to eq(false)
    end

    it "ignores a race's requirement when requirement.enabled? == false" do
      FactoryBot.create :payment_requirement, :race => @race
      expect(@reg.completed_all_requirements?).to eq(true)
    end
  end
end
