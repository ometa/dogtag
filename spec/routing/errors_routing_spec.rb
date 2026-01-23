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

describe "Error routes", type: :routing do
  describe "root path with non-GET methods" do
    it "routes POST / to errors#not_found" do
      expect(post: "/").to route_to(controller: "errors", action: "not_found")
    end

    it "routes PUT / to errors#not_found" do
      expect(put: "/").to route_to(controller: "errors", action: "not_found")
    end

    it "routes PATCH / to errors#not_found" do
      expect(patch: "/").to route_to(controller: "errors", action: "not_found")
    end

    it "routes DELETE / to errors#not_found" do
      expect(delete: "/").to route_to(controller: "errors", action: "not_found")
    end
  end

  describe "catch-all route for unmatched paths" do
    it "routes GET to unknown paths to errors#not_found" do
      expect(get: "/.env").to route_to(controller: "errors", action: "not_found", path: ".env")
    end

    it "routes POST to unknown paths to errors#not_found" do
      expect(post: "/wp-admin").to route_to(controller: "errors", action: "not_found", path: "wp-admin")
    end
  end

  describe "root path with GET" do
    it "routes GET / to homepages#index" do
      expect(get: "/").to route_to(controller: "homepages", action: "index")
    end
  end
end
