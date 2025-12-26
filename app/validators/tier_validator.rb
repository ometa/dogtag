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
class TierValidator < ActiveModel::Validator

  def validate(record)
    validate_unique_begin_at(record)
    validate_unique_price(record)
  end

  private

  def validate_unique_begin_at(record)
    tiers = non_self_tiers(record)
    return unless tiers.present?
    # Rails 7.0: Use any? with explicit comparison instead of include?
    # to handle datetime precision issues
    if tiers.any? { |t| t.begin_at == record.begin_at }
      record.errors.add(:begin_at, 'must be unique per payment requirement')
    end
  end

  def validate_unique_price(record)
    tiers = non_self_tiers(record)
    return unless tiers.present?
    # Rails 7.0: Use any? with explicit comparison
    if tiers.any? { |t| t.price == record.price }
      record.errors.add(:price, 'must be unique per payment requirement')
    end
  end

  # helper method

  def non_self_tiers(record)
    return [] unless record.requirement.present?

    # Rails 7.0: Explicitly reload association to get current state from database
    # This ensures we see all previously saved tiers
    record.requirement.tiers.reload if record.requirement.tiers.loaded?
    tiers = record.requirement.tiers.to_a

    # Filter out the current record by comparing database IDs
    # (can't use object_id since reloaded records have different object_ids)
    tiers.reject { |t| t.id.present? && t.id == record.id }
  end
end
