require 'spec_helper'

describe Team do

  describe 'scopes' do
    describe 'all_finalized' do
      before do
        @finalized = FactoryGirl.create :finalized_team
        FactoryGirl.create :team
      end

      it 'returns only finalized teams' do
        expect(Team.all_finalized).to eq([@finalized])
      end
    end

    describe 'all_unfinalized' do
      before do
        FactoryGirl.create :finalized_team
        @unfinalized = FactoryGirl.create :team
      end

      it 'returns only finalized teams' do
        expect(Team.all_unfinalized).to eq([@unfinalized])
      end
    end
  end

  describe 'validation' do
    let(:race) { FactoryGirl.create :race }
    let(:team) { FactoryGirl.create :team }

    context 'succeeds' do
      it 'when all required parameters are present' do
        expect(team).to be_valid
      end

      it 'when a race is open' do
        expect(FactoryGirl.build :team, race: race).to be_valid
      end
    end

    context 'fails' do
      it 'when the same team name registers for a race more than once' do
        expect(FactoryGirl.create :team, name: 'mushfaces', race: race).to be_valid
        expect(FactoryGirl.build :team, name: 'mushfaces', race: race).to be_invalid
      end
    end

    it 'a team can be named the same in different races' do
      race2 = FactoryGirl.create :race
      expect(FactoryGirl.create :team, name: 'mushfaces', race: race).to be_valid
      expect(FactoryGirl.build :team, name: 'mushfaces', race: race2).to be_valid
    end
  end

  describe '.finalize' do

    context 'not yet finalized and meets all requirements' do

      let(:team) { FactoryGirl.create :team, :with_enough_people }

      it 'sets finalized flat and notified_at in the db' do
        Timecop.freeze(THE_TIME) do
          team.finalize
          record = Team.find(team.id)
          expect(record.notified_at.to_datetime).to eq(THE_TIME.to_datetime)
          expect(record.finalized).to be_truthy
        end
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
            team.unfinalize
            team.finalize
            team.reload
            expect(team.assigned_team_number).to eq(1)
          end
        end

        context 'when there are teams that used to be finalized and now are not' do
          it 'skips over the formerly assigned team number to a new one' do
            t = FactoryGirl.create :finalized_team, race: team.race
            t.unfinalize
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
        expect(Workers::TeamFinalizer).to receive(:perform_async).with({team_id: team.id})
        team.finalize
      end
    end
  end

  describe '.unfinalize' do

    context 'called on a unfinalized team' do
      let(:team) { FactoryGirl.create :team, :with_enough_people }

      it 'returns nil' do
        expect(team.unfinalize).to be_nil
      end
    end

    context 'called on a finalized team' do
      let(:team) { FactoryGirl.create :finalized_team }

      it 'unsets finalized flat and notified_at in the db' do
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
      team = FactoryGirl.create :team
      expect(team.unfinalized).to be_truthy
    end

    it 'returns false when team is finalized 'do
      team = FactoryGirl.create :finalized_team
      expect(team.unfinalized).to be_falsey
    end
  end

  describe '.person_experience' do

    context "when there are no people on the team" do
      let(:team) { FactoryGirl.create :team }
      it "returns 0" do
        expect(team.person_experience).to eq(0)
      end
    end

    context "when there are people on the team" do
      let(:team) { FactoryGirl.create :team, :with_enough_people }
      it "sums their total experience" do
        expect(team.person_experience).to eq(6)
      end
    end
  end

  describe '.jsonform_value' do
    let(:key) { "racer-type" }

    context 'when team has no jsonform data' do
      let(:team) { FactoryGirl.create :team }
      it 'returns nil' do
        expect(team.jsonform_value(key)).to be_nil
      end
    end

    context "when team's jsonform has the value" do
      let(:team) { FactoryGirl.create :team_with_jsonform }
      it 'returns the value' do
        expect(team.jsonform_value(key)).to eq("Racer")
      end
    end

    context 'when team does not have jsonform data for a certain key' do
      let(:team) { FactoryGirl.create :team_with_jsonform }
      it 'returns nil' do
        expect(team.jsonform_value("foo")).to be_nil
      end
    end
  end

  describe '#completed_questions?' do

    context 'race has no jsonform' do
      let(:race) { FactoryGirl.create :race }
      let(:team) { FactoryGirl.create :team, race: race }
      it "returns true" do
        expect(team.completed_questions?).to be true
      end
    end

    context 'race has a jsonform' do

      context 'team has jsonform data' do
        let(:team) { FactoryGirl.create :team_with_jsonform }

        it "returns true" do
          expect(team.completed_questions?).to be true
        end
      end

      context 'team has no jsonform data' do
        let(:race) { FactoryGirl.create :race_with_jsonform }
        let(:team) { FactoryGirl.create :team, race: race }

        it "returns false" do
          expect(team.completed_questions?).to be false
        end
      end
    end
  end

  describe ".money_paid_in_cents" do
    it "reports the amount of money a team has paid according to its completed requirements"
  end

  describe '#export' do
    it 'sets the correct columns'
    it 'returns a multi-dimensional array of teams'
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
      let(:req)  { FactoryGirl.create :payment_requirement }
      let(:team) { FactoryGirl.create :team, race: req.race}

      include_examples "returns correct percentage"
    end

    context "when no people have been added and payment requirements are satisfied" do
      let(:req)  { FactoryGirl.create :payment_requirement_with_tier }
      let(:team) { FactoryGirl.create :team, race: req.race }
      let!(:cr)  { FactoryGirl.create :completed_requirement, requirement: req, team: team }

      include_examples "returns correct percentage"
    end

    context "when some people have been added and payment requirements are not satisfied" do
      let(:req)  { FactoryGirl.create :payment_requirement_with_tier }
      let(:team) { FactoryGirl.create :team, :with_people, race: req.race }

      include_examples "returns correct percentage"
    end

    context "when some people have been added and payment requirements are satisfied" do
      let(:team) { FactoryGirl.create :team, :with_people }
      let(:req)  { FactoryGirl.create :payment_requirement_with_tier, race: team.race }
      let!(:cr)  { FactoryGirl.create :completed_requirement, requirement: req, team: team }

      include_examples "returns correct percentage"
    end

    context "when all people have been added and payment requirements are satisfied" do
      let(:team) { FactoryGirl.create :team, :with_enough_people }
      let(:req)  { FactoryGirl.create :payment_requirement_with_tier, race: team.race }
      let!(:cr)  { FactoryGirl.create :completed_requirement, requirement: req, team: team }

      include_examples "returns correct percentage"
    end

    context 'when race has some jsonschema' do
      context 'and team does not'
      context 'and team does also'
    end
  end

  describe '#needs_people?' do
    let(:race) { FactoryGirl.create :race }
    let(:reg)  { FactoryGirl.create :team, :with_people, :race => race }

    it 'returns true if there are less than race.people_per_team people' do
      expect(reg.needs_people?).to be true
    end

    it 'returns false if there are race.people_per_team people' do
      reg.people << FactoryGirl.create(:person)
      expect(reg.needs_people?).to be false
    end
  end

  describe '#waitlist_position' do
    it 'returns our position on the waitlist by created_at date'
  end

  describe '#is_full?' do
    it 'should be the opposite of #needs_people?' do
      reg = FactoryGirl.create :team
      allow(reg).to receive(:needs_people?).and_return false
      expect(reg.is_full?).to eq(true)
    end
  end

  describe '#meets_finalization_requirements?' do
    before do
      @reg = FactoryGirl.create :team
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
      @reg = FactoryGirl.create :team
      @race = @reg.race
      req = FactoryGirl.create :enabled_payment_requirement, :race => @race
      FactoryGirl.create :completed_requirement, :requirement => req, :team => @reg
    end

    it 'returns true when a race has no requirements' do
      reg = FactoryGirl.create :team
      expect(reg.completed_all_requirements?).to eq(true)
    end

    it 'returns true when all enabled requirements are completed' do
      expect(@reg.completed_all_requirements?).to eq(true)
    end

    it 'return false if any enabled requirements are not completed' do
      FactoryGirl.create :enabled_payment_requirement, :race => @race
      expect(@reg.completed_all_requirements?).to eq(false)
    end

    it "ignores a race's requirement when requirement.enabled? == false" do
      FactoryGirl.create :payment_requirement, :race => @race
      expect(@reg.completed_all_requirements?).to eq(true)
    end
  end
end
