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
  class TeamStatusWatchdog
    include Sidekiq::Worker
    include Workers::Common

    sidekiq_options queue: :important, retry: false, backtrace: true
    sidekiq_options failures: true

    def run(_job, data={})

      data[:team_ids_finalized] = Team.all_unfinalized.select { |t| t.meets_finalization_requirements? }.map do |team|
        team.finalize
        team.id
      end

      data[:team_ids_unfinalized] = Team.all_finalized.select { |t| ! t.meets_finalization_requirements? }.map do |team|
        team.unfinalize
        team.id
      end

      log("complete", data)
    end
  end
end
