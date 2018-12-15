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
FactoryBot.define do
  factory :requirement do
    name { 'Requirement' }
    race

    #todo -get rid of this
    factory :requirement2 do
      name { 'Requirement 2' }
    end
  end

  factory :payment_requirement do
    name { "Payment Requirement '#{ Faker::Name.unique.name }'" }
    type { 'PaymentRequirement' }
    race

    factory :payment_requirement_with_tier, :aliases => [:enabled_payment_requirement] do
      name { 'Payment Requirement w/ tier' }
      after(:create) do |pay_req, evaluator|
        create_list(:tier, 1, requirement_id: pay_req.id)
      end
    end
  end
end
