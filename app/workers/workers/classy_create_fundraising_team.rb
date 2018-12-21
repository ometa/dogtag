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
  class ClassyCreateFundraisingTeam
    include Sidekiq::Worker
    include Workers::Common

    sidekiq_options queue: :important, retry: true, backtrace: true
    sidekiq_options failures: true

    # create a new classy fundraising team and associate it with a dogtag team
    # idempotent; will not re-create if there's already a classy team
    def run(job, log={})
      team = Team.includes(:user).includes(:race).find(job['team_id'])
      user = team.user
      race = team.race

      if team.classy_id.present?
        log[:message] = "Team id: #{team.id} already has a classy team fundraiser id of #{team.classy_id}"
        log("complete", log)
        return
      end

      unless (campaign_id = race.classy_campaign_id)
        log("no-op", message: "No classy campaign id set for race id: #{race.id}, therefore we cannot create a fundraising team")
        return
      end

      unless (default_goal = race.classy_default_goal)
        log("no-op", message: "No classy default fundraising goal set for race id: #{race.id}, therefore we cannot create a fundraising team")
        return
      end

      ClassyUser.link_user_to_classy!(user, race)

      cc = ClassyClient.new
      result = cc.create_fundraising_team(campaign_id, team.name, team.description, user.classy_id, default_goal)
      team.classy_id = result['id']
      team.save!
      log[:response] = result
      log[:message] = "Success adding a classy fundraising team for team id: #{team.id}"
      log("complete", log)

      # create a fundraising page so this team can do something
      new_job = { 'team_id' => team.id }
      Workers::ClassyCreateFundraisingPage.perform_async(new_job)
    end
  end
end
