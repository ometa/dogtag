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
FactoryBot.define do

  factory :user do
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    email      { Faker::Internet.unique.email }

    phone { '312-867-5309' }
    password { '123456' }
    password_confirmation { '123456' }

    factory :admin_user do
      roles { [:admin] }
    end

    factory :operator_user do
      roles { [:operator] }
    end

    factory :refunder_user do
      roles { [:refunder] }
    end

    factory :user2 do
      first_name { 'Mr' }
      last_name { 'Anderson' }
      email { 'mr@anderson.com' }
    end

    trait :with_classy_id do
      classy_id { 123456 }
    end

    trait :with_stripe_account do
      stripe_customer_id { "stripe_customer_#{ Faker::Number.unique.number(5) }" }
    end
  end
end
