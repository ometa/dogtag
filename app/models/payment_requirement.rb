# Copyright (C) 2014 Devin Breen
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
class PaymentRequirement < Requirement
  has_many :tiers, :foreign_key => :requirement_id, :dependent => :delete_all

  def ready?
    tiers.present?
  end

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

  def active_tier
    chronological_tiers.select do |tier|
      tier.begin_at < Time.zone.now
    end.last || false
  end

  def next_tiers
    chronological_tiers.select do |tier|
      tier.begin_at >= Time.zone.now
    end || []
  end

  private

  def chronological_tiers
    @chronological_tiers ||= tiers.sort_by(&:begin_at)
  end
end
