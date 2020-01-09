require 'spec_helper'

describe "CompletedRequirementAuditor" do

  let(:user) { FactoryBot.create :user }
  let(:req)  { FactoryBot.create :payment_requirement_with_tier }
  let(:cr)   { FactoryBot.build :cr, requirement: req, team: team, user: user }

  before do
    cr.subscribe(CompletedRequirementAuditor.new)
  end

  context "a completed requirement gets created and the team now meets all requirements" do
    let(:team) { FactoryBot.create :team, :with_enough_people, race: req.race, user: user }

    it "the team becomes finalized" do
      expect(team.finalized?).to be false
      cr.save
      expect(team.reload.finalized?).to be true
    end
  end

  context "a completed requirement gets created but the team does not meet all requirements" do
    let(:team) { FactoryBot.create :team, :with_people, race: req.race, user: user }

    it "the team stays unfinalized" do
      expect(team.finalized?).to be false
      cr.save
      expect(team.reload.finalized?).to be false
    end
  end

  context "a completed requirement associated with a finalized team gets deleted" do
    let(:team) { FactoryBot.create :team, :with_enough_people, race: req.race }
    let(:cr)   { FactoryBot.create :cr, requirement: req, team: team, user: user }
    it "the team becomes unfinalized" do
      team.finalize
      expect(team.finalized?).to be true
      cr.destroy
      expect(team.reload.finalized?).to be false
    end
  end
end
