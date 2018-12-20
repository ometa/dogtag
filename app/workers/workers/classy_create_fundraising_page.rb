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
module Workers
  class ClassyCreateFundraisingPage
    include Sidekiq::Worker
    include Workers::Common

    sidekiq_options queue: :important, retry: true, backtrace: true
    sidekiq_options failures: true

    # Create a new fundraiser page, owned by 'user', associated with the 'team'
    # fundraiser pages are owned by individual users. since we only have guaranteed email and other info
    # from the dogtag user account, associate this fundraiser page with that user.
    def run(job, log={})
      team = Team.includes(:user).includes(:race).find(job['team_id'])
      user = team.user
      race = team.race

      if team.classy_fundraiser_page_id.present?
        log[:message] = "Team id: #{team.id} already has a classy team fundraiser page of #{team.classy_fundraiser_page_id}"
        log("complete", log)
        return
      end

      unless team.classy_id.present?
        log("no-op", message: "Team id: #{team.id} does not have a classy ID. Set that first")
        return
      end

      unless user.classy_id.present?
        log("no-op", message: "User id: #{user.id} does not have a classy ID. Set that first")
        return
      end

      cc = ClassyClient.new
      classy_team = cc.get_fundraising_team(team.classy_id)

      result = cc.create_fundraising_page(
        "#{race.name} Fundraiser: #{team.name}",
        race.classy_default_goal,
        classy_team["created_at"]
      )

      # TODO: might be able to remove this hard-coded id now
      # see https://developers.classy.org/api-docs/v2/index.html#fundraising-pages
      team.classy_fundraiser_page_id = result['id']
      team.save!

      cc.transfer_fundraising_page_to_team(result['id'], team.classy_id)

      UserMailer.classy_is_ready(user, team).deliver_now

      log[:response] = result
      log[:message] = "Success adding a classy fundraising page for team id: #{team.id}"
      log("complete", log)
    end
  end
end
