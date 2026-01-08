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
class PersonValidator < ActiveModel::Validator
  def validate(record)
    ensure_editing_is_ok(record)
    validate_person_count(record)
  end

  def ensure_editing_is_ok(record)
    if record.team.present? && record.team.race.present?
      race = record.team.race
      if !(race.open_for_registration? || race.in_final_edits_window?)
        record.errors.add(:generic, "cannot edit this information after the final edit date")
      end
    end
  end

  def validate_person_count(record)
    # Only validate person count when creating new records, not when updating
    return unless record.new_record?

    if record.team.present? && record.team.race.present?
      if record.team.people.count == record.team.race.people_per_team
        record.errors.add(:maximum, "people already added to this team")
      end
    end
  end
end
