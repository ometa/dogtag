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
  factory :tier do
    transient do
      thetime { Time.zone.now }
    end

    price { 5000 }
    begin_at { thetime - 2.weeks }

    trait :opening_in_the_future do
      begin_at { thetime + 2.weeks }
    end

    factory :tier2 do
      price { 6000 }
      begin_at { thetime - 2.days }
    end

    factory :tier3 do
      price { 7000 }
      begin_at { thetime + 2.weeks }
    end
  end
end
