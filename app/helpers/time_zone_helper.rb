module TimeZoneHelper
  # e.g. "Central Time (CST/CDT)" or "Edinburgh, London (GMT/BST)".
  def time_zone_label(iana)
    zone = ActiveSupport::TimeZone[iana.to_s]
    return iana.to_s unless zone

    names = ActiveSupport::TimeZone::MAPPING.select { |_name, id| id == iana }.keys
    name = names.any? ? names.join(", ").delete_suffix(" (US & Canada)") : iana
    year = Time.now.utc.year
    abbreviations = [1, 7].map { |month| zone.period_for_utc(Time.utc(year, month, 1)).abbreviation }.uniq
    "#{name} (#{abbreviations.join("/")})"
  end

  # Grouped options with IANA ids as values; US zones first. Each option
  # carries its time_zone_label so the race form can relabel its date fields.
  def time_zone_options(selected)
    zones = ActiveSupport::TimeZone.all.group_by { |zone| zone.tzinfo.name }
    options = zones.map do |iana, named|
      ["(GMT#{named.first.formatted_offset}) #{named.map(&:name).join(", ")}", iana, { "data-zone-label" => time_zone_label(iana) }]
    end
    us_ids = ActiveSupport::TimeZone.us_zones.map { |zone| zone.tzinfo.name }
    us, other = options.partition { |_label, iana, _data| us_ids.include?(iana) }
    us = us.sort_by { |label, iana| [-ActiveSupport::TimeZone[iana].utc_offset, label] }
    grouped_options_for_select({ "United States" => us, "Other" => other }, selected)
  end
end
