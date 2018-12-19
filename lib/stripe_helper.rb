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
class StripeHelper
  class << self

    def safely_call_stripe
      begin
        yield
        [true, nil]

      rescue Stripe::CardError => e
        # Stripe::CardError will be caught if card is declined.

        Rails.logger.error e.class
        Rails.logger.error "HTTP status: #{e.http_status}"

        if e.json_body.present? && e.json_body[:error].present?
          err = e.json_body[:error]
          Rails.logger.error "type: #{err[:type]}"
          Rails.logger.error "code: #{err[:code]}"
          Rails.logger.error "param: #{err[:param]}"
          Rails.logger.error "message: #{err[:message]}"
        end

      rescue Stripe::AuthenticationError, Stripe::APIConnectionError,
        Stripe::StripeError, Stripe::InvalidRequestError => ex

        Rails.logger.error(ex)
        [false, ex]

      #TODO: change to StandardError, consider deleting altogether
      rescue => ex
        Rails.logger.error(ex)
        [false, ex]
      end
    end

    # TODO: consider removing
    def exception_to_hash(ex)
      hash = {
        class: ex.class.to_s,
        reason: ex.message
      }

      if ex.respond_to?(:http_status) && ex.http_status
        hash[:http_status] = ex.http_status
      end

      if ex.respond_to?(:json_body) && ex.json_body.present? && ex.json_body[:error].present?
        json = ex.json_body[:error]
        hash.merge!(
          {
            type: json[:type],
            code: json[:code],
            param: json[:param],
            message: json[:message]
          }
        )
      end

      hash
    end
  end
end
