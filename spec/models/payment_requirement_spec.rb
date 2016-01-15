require 'spec_helper'

describe PaymentRequirement do

  let (:req)   { FactoryGirl.create :payment_requirement }
  let (:tier1) { FactoryGirl.create :tier }
  let (:tier2) { FactoryGirl.create :tier2 }
  let (:tier3) { FactoryGirl.create :tier3 }

  describe '#stripe_params' do
    it 'sets the description to the name of the payment requirement'
    it 'stores the requirement_id and team_id in the metadata'
    it 'sets the amount of the active_tier'
    it 'sets an image'
    it 'sets the company name to the race name'
  end

  before { Timecop.freeze(THE_TIME) }
  after  { Timecop.return }

  describe '#enabled?' do
    it 'returns false when no tiers are assigned' do
      expect(req.enabled?).to be_false
    end

    it 'returns true when there are tiers' do
      req.tiers << tier1
      expect(req.enabled?).to be_true
    end

    it 'return false when all tiers are in the future' do
      req.tiers << tier3
      expect(req.enabled?).to be_false
    end
  end

  describe '#next_tier' do
    it 'returns [] if no tiers are defined' do
      expect(req.next_tiers).to be_empty
    end

    it 'returns [] if only 1 tier is defined' do
      req.tiers << tier1
      expect(req.next_tiers).to be_empty
    end

    it 'returns [] if there are no upcoming tiers' do
      req.tiers = [tier1, tier2]
      expect(req.next_tiers).to be_empty
    end
    it 'returns tiers if is a tier in front of the active tier' do
      req.tiers = [tier1, tier2, tier3]
      expect(req.next_tiers).to eq([tier3])
    end
  end

  describe '#active_tier' do

    it 'returns false if no tiers are defined' do
      expect(req.active_tier).to be_false
    end

    it 'returns the tier if only 1 tier is defined' do
      req.tiers << tier1
      expect(req.active_tier).to eq(tier1)
    end

    it 'returns correct tier if a former tier has expired' do
      req.tiers = [tier1, tier2]
      expect(req.active_tier).to eq(tier2)
    end

    it 'returns correct tier if there are tiers expired in the past and untriggered tiers in the future' do
      req.tiers = [tier1, tier2, tier3]
      expect(req.active_tier).to eq(tier2)
    end

    it 'returns false if all tiers are in the future' do
      req.tiers << tier3
      expect(req.active_tier).to eq(false)
    end
  end
end
