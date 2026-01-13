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
require "spec_helper"

describe ErrorsController do
  describe "#not_found" do
    it "returns 404 status for HTML requests" do
      get :not_found, params: { path: ".env" }
      expect(response).to have_http_status(:not_found)
    end

    it "renders the 404 template" do
      get :not_found, params: { path: ".env" }
      expect(response).to render_template("error/404")
    end

    it "returns 404 status for JSON requests" do
      get :not_found, params: { path: "api/missing" }, format: :json
      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq({ "error" => "Not found" })
    end

    it "handles POST requests" do
      post :not_found, params: { path: "some/path" }
      expect(response).to have_http_status(:not_found)
    end

    it "handles various bot scanning paths" do
      [".env", "wp-admin", ".git/config", "phpinfo.php"].each do |bot_path|
        get :not_found, params: { path: bot_path }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
