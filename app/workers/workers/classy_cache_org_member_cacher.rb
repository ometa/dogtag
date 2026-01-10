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
module Workers
  class ClassyCacheOrgMemberCacher
    include Sidekiq::Worker
    include Workers::Common

    # run this cronjob no more frequently than this. See config/schedule.yaml
    LOCK_TTL = 15.minutes.to_i

    sidekiq_options queue: :default, retry: false, backtrace: true
    sidekiq_options failures: true
    sidekiq_options lock: :until_expired, lock_ttl: LOCK_TTL,
                    on_conflict: { client: :log, server: :reject }

    # fetch all organization supporters from classy api and cache them
    def run(job, log={})
      cc = ClassyClient.new

      records = []
      orgs = ENV.fetch("CLASSY_ORGS","")
      if orgs == ""
        log("no org ids found in CLASSY_ORGS")
        return
      end

      orgs.split(",").each do |org_id|
        page = 0
        cc.with_supporters(org_id) do |data|
          page += 1
          log("fetched org supporter records", {page: page}, :debug)
          data.each do |item|
            # we only care about org supporter records that are complete
            # TODO: it's debatable that we need the classy updated_at if we can assume that member ids are monotonicly increasing. however, it's safer to sort by updated_at to protect against classy changing their API.
            if item["member_id"].nil? || item["email_address"].nil? || item["updated_at"].nil?
              log("skipping record; missing data", {}, :debug)
              next
            end

            record = {
              classy_org_id: org_id.to_i, email: item["email_address"],
              classy_member_id: item["member_id"], classy_updated_at: item["updated_at"]
            }
            log("adding record", record, :debug)
            records << record
          end
        end
        log("classy api fetch complete", {org_id: org_id, pages: page})
      end

      # use activerecord-import gem to bulk-insert all rows in a single SQL transaction with upsert
      ClassyCacheOrgMember.import(records, validate: true, on_duplicate_key_update: {conflict_target: [:email, :classy_member_id, :classy_updated_at], columns: [:classy_member_id]})

      log("inserted records into db", {size: records.size})
    end
  end
end
