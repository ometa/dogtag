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
class Ability
  include CanCan::Ability

  # See the wiki for details:
  # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
  def initialize(user)

    # anonymous
    can [:create], User
    can [:index, :show], Race

    return unless user.present?

    # logged-in user

    # User can create and manage itself
    can [:show, :edit, :update], User, :id => user.id

    can [:index, :create], Team
    can [:index, :show, :edit], Team, user_id: user.id
    can [:update], Team do |team|
      team.user_id == user.id && team.race.open_for_registration?
    end

    can [:show, :create], :questions

    can [:create], :charges

    #todo implement at some point
    #can [:destroy], Team do |team|
      #user.id == team.user_id && team.completed_requirements.empty?
    #end

    can [:registrations], Race

    can [:create], Person
    can [:show, :edit, :update], Person do |person|
      user.team_ids.include?(person.team.id) && (person.team.race.open_for_registration? || person.team.race.in_final_edits_window?)
    end

    # Requirement
    # no user-level access required

    # Tier
    # no user-level access required

    if user.is? :refunder
      can [:index], User
      can [:index, :show], Team
      can [:refund], :charges
    end

    if user.is? :operator
      can [:export], Race
      can [:index, :show, :edit, :update], [Team, Person]
      can [:index, :show, :edit, :update, :create], [Race, PaymentRequirement, Tier]
      can [:refund], :charges
    end

    if user.is? :admin
      can :manage, :all
    end
  end
end
