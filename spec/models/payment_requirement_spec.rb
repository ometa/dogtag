require 'spec_helper'

describe PaymentRequirement do

  let (:req)   { FactoryGirl.create :payment_requirement }
  let (:tier1) { FactoryGirl.create :tier }
  let (:tier2) { FactoryGirl.create :tier2 }
  let (:tier3) { FactoryGirl.create :tier3 }

  before { Timecop.freeze(THE_TIME) }
  after  { Timecop.return }

  describe '#stripe_params' do
    let(:req)  { FactoryGirl.create :payment_requirement_with_tier }
    let(:team) { FactoryGirl.create :team, race: req.race }

    let(:expected) {{
      description: "#{req.name} for #{team.name} | #{team.race.name}",
      metadata: JSON.generate(
        'race_name' => team.race.name,
        'team_name' => team.name,
        'requirement_id' => req.id,
        'team_id' => team.id
      ),
      amount: req.active_tier.price,
      image: '/images/patch_ring.jpg',
      name: team.race.name
    }}

    it 'creates a hash of data for submission to stripe' do
      expect(req.stripe_params(team)).to eq(expected)
    end
  end

  describe '#enabled?' do
    it 'returns false when no tiers are assigned' do
      expect(req.enabled?).to be false
    end

    it 'returns true when there are tiers' do
      req.tiers << tier1
      expect(req.enabled?).to be true
    end

    it 'return false when all tiers are in the future' do
      req.tiers << tier3
      expect(req.enabled?).to be false
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
      expect(req.active_tier).to be false
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
      expect(req.active_tier).to be false
    end
  end
end
