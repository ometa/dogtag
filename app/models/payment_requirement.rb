class PaymentRequirement < Requirement
  has_many :tiers, :foreign_key => :requirement_id, :dependent => :delete_all
  include Wisper.model

  def stripe_params(team)
    metadata = JSON.generate(
      'race_name' => team.race.name,
      'team_name' => team.name,
      'requirement_id' => id,
      'team_id' => team.id
    )

    {
      :description => "#{name} for #{team.name} | #{team.race.name}",
      :metadata => metadata,
      :amount => active_tier.price,
      :image => '/images/patch_ring.jpg',
      :name => team.race.name
    }
  end

  def charge_data(reg)
    metadata = metadata_for(reg)
    return false if metadata.blank?
    return metadata['charge'] if metadata['charge'].present?
    false

    # todo: after specing replace with this
    #return false unless (metadata.present? && metadata['charge'].present?)
    #return metadata['charge']
  end

  def enabled?
    active_tier.present?
  end

  def active_tier
    chronological_tiers.select do |tier|
      tier.begin_at < Time.now
    end.last || false
  end

  def next_tiers
    chronological_tiers.select do |tier|
      tier.begin_at >= Time.now
    end || []
  end

  private

  def chronological_tiers
    @chronological_tiers ||= tiers.sort_by(&:begin_at)
  end
end
