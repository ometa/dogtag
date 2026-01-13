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
class ErrorsController < ApplicationController
  # Skip authentication for error pages
  skip_before_action :verify_authenticity_token

  def not_found
    respond_to do |format|
      format.html { render template: "error/404", status: :not_found }
      format.json { render json: { error: "Not found" }, status: :not_found }
      format.all { head :not_found }
    end
  end
end
