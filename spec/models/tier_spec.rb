require 'spec_helper'

describe Tier do

  let(:thetime) { Time.local(1980, 9, 1, 12, 0, 0) }
  before { Timecop.freeze(thetime) }
  after  { Timecop.return }

  let!(:req) do
    Timecop.freeze(thetime) do
      FactoryGirl.create :payment_requirement_with_tier
    end
  end

  let(:tier) { req.reload.tiers.first }

  describe 'validation' do
    it 'fails when price is not above 0' do
      expect(FactoryGirl.build :tier, :price => -1).to be_invalid
    end

    it 'fails when price is not a number' do
      expect(FactoryGirl.build :tier, :price => 'a').to be_invalid
    end

    it 'fails when another tier has the same "begin_at" value' do
      tier2 = FactoryGirl.build :tier, :price => 6000
      req.tiers << tier2
      expect(tier2).to be_invalid
    end

    it 'fails when another tier has the same "price" value' do
      tier2 = FactoryGirl.build :tier, :begin_at => (Time.now - 4.weeks)
      req.tiers << tier2
      expect(tier2).to be_invalid
    end

    it 'passes when two tiers with the same information are assigned to different requirements' do
      req2 = FactoryGirl.create :payment_requirement
      tier2 = FactoryGirl.create(:tier)
      req2.tiers << tier2
      expect(tier2).to be_valid
    end
  end
end
