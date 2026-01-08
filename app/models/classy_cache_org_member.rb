# Copyright (C) 2013 Devin Breen
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
class ClassyCacheOrgMember < ApplicationRecord
  before_validation :downcase_email

  validates :classy_org_id, :email, :classy_member_id, :classy_updated_at, presence: true
  validates :email, format: { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }
  validate :email_must_be_lowercase
  validates :classy_org_id, :classy_member_id, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0 }

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end

  def email_must_be_lowercase
    return if email.blank?
    if email != email.downcase
      errors.add(:email, 'must be lowercase')
    end
  end
end
