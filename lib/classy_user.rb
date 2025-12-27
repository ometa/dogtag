# Copyright (C) 2017 Devin Breen
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
class ClassyUser

  # associate dogtag user account with an existing classy user, or tell classy
  # to make a new association and send them an invite to the classy platform.

  # link_user_to_classy! associates a dogtag user to a classy account. it gracefully
  # handles various states of a classy user account and the required machinations to retrieve the
  # classy member_id and associate it with the dogtag user. classy will handle sending an invite
  # email to the email address if the email is not already associated with a classy account.
  #
  # TODO: do not inject race, instead inject an org_id. the org_id can be derived from the race classy_campaign_id
  #       through an api call to get_campaign(), but it would be easier to explicitly set the org_id on the race object
  def self.link_user_to_classy!(user, race)
    cc = ClassyClient.new
    campaign_data = cc.get_campaign(race.classy_campaign_id)
    organization_id = campaign_data['organization_id']

    # step 1 - attempt to create a classy member (which also creates a classy organization supporter)
    response = cc.create_member(organization_id, user.first_name, user.last_name, user.email)
    b = JSON.parse(response.body)

    # a 200 response means the classy API created both a member and supporter record
    # and it returns the classy member id, which we need later to create fundraising teams
    if response.ok?
      user.classy_id = b['id'].to_i
      user.save!
      Rails.logger.info "successfully created classy organization member & supporter with classy id: #{user.classy_id}"
      return user
    end

    # a 400 response with "email already used" means classy knows about this user but it's
    # unclear if a classy supporter exists for the classy org, so we need to ensure there is one.
    err_email_used = /This email address is already used/
    if response.code == 400 && Array(b.dig("error", "email_address")).index{|e| e =~ err_email_used} != nil

      Rails.logger.info "classy reported member account already exists for email: #{user.email}"

      # step 2 - attempt to add the user as a supporter for the classy org id
      response = cc.create_supporter(organization_id, user.first_name, user.last_name, user.email)
      b = JSON.parse(response.body)

      # a 200 response means the classy API created a supporter record and we are done
      if response.ok?
        user.classy_id = b['member_id'].to_i
        user.save!
        Rails.logger.info "successfully created classy organization supporter with classy id: #{user.classy_id}"
        return user
      end

      # a 400 response with classy indicating that the member already being a supporter means it does not
      # return the existing member_id. we need to query for it in the local classy cache
      err_member_id_used = /is already a supporter for Organization/
      if response.code == 400 && Array(b.dig("error", "member_id")).index{|e| e =~ err_member_id_used} != nil
        Rails.logger.info "classy reported supporter account already exists for email: #{user.email}"

        # select the most recent record for this email and use that classy member id
        record = ClassyCacheOrgMember.where(email: user.email).order(classy_updated_at: :desc).limit(1).first
        if record.nil?
          Rails.logger.info "did not find classy member_id in cache for email: #{user.email}"
          return
        end
        Rails.logger.info "found classy member_id: #{record.classy_member_id} in classy cache for email: #{user.email}"
        user.classy_id = record.classy_member_id
        user.save!
      else
        # an unhandled response code and message from create_supporter
        raise TransientError.new("error: create_supporter: #{response.status}: #{response.body}")
      end
    else
      # an unhandled response code and message from create_member
      raise TransientError.new("error: create_member: #{response.status}: #{response.body}")
    end
  end
end
