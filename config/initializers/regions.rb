# Beacon region configuration
# Defines available monitoring regions and their settings

module Beacon
  REGIONS = {
    "nyc" => {
      name: "New York",
      location: "US East",
      timezone: "America/New_York"
    },
    "lon" => {
      name: "London",
      location: "Europe West",
      timezone: "Europe/London"
    },
    "sin" => {
      name: "Singapore",
      location: "Asia Pacific",
      timezone: "Asia/Singapore"
    },
    "syd" => {
      name: "Sydney",
      location: "Australia",
      timezone: "Australia/Sydney"
    }
  }.freeze

  # Current region this worker is running in
  def self.current_region
    ENV.fetch("BEACON_REGION", "nyc")
  end

  def self.region_name(code)
    REGIONS.dig(code, :name) || code.upcase
  end

  def self.all_regions
    REGIONS.keys
  end
end
