require 'spec_helper'

describe TeamSubscriber do
  context "when Team is committed" do
    let(:team) { FactoryGirl.build :team }

    it "calls team.unfinalize and team.finalize" do
      expect do
        team.save
      end.to broadcast(:after_commit)
    end
  end
end
