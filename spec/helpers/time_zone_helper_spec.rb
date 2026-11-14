require "spec_helper"

describe TimeZoneHelper, type: :helper do
  describe "#time_zone_label" do
    it "names the zone with its standard and daylight abbreviations" do
      expect(time_zone_label("America/Chicago")).to eq("Central Time (CST/CDT)")
      expect(time_zone_label("America/Phoenix")).to eq("Arizona (MST)")
    end
  end

  describe "#time_zone_options" do
    it "lists US zones first with IANA ids as values" do
      page = Nokogiri::HTML.fragment(time_zone_options("America/Chicago"))
      groups = page.css("optgroup")

      expect(groups.map { |group| group["label"] }).to eq(["United States", "Other"])
      expect(groups.first.css("option").map { |option| option["value"] }).to include("America/New_York", "America/Los_Angeles")
      expect(page.at_css("option[selected]")["value"]).to eq("America/Chicago")
      expect(page.at_css("option[selected]").text).to eq("(GMT-06:00) Central Time (US & Canada)")
    end
  end
end
