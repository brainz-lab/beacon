class Project < ApplicationRecord
  has_many :monitors, dependent: :destroy
  has_many :status_pages, dependent: :destroy
  has_many :maintenance_windows, dependent: :destroy

  validates :platform_project_id, presence: true, uniqueness: true
  validates :api_key, presence: true, uniqueness: true

  before_validation :generate_keys, on: :create

  # Find or create project from Platform
  def self.find_or_create_from_platform(platform_project_id:, name: nil)
    find_or_create_by!(platform_project_id: platform_project_id) do |project|
      project.name = name
    end
  end

  # Find by API key
  def self.find_by_api_key(key)
    find_by(api_key: key) || find_by(ingest_key: key)
  end

  def monitors_summary
    {
      total: monitors.count,
      up: monitors.up.count,
      down: monitors.down.count,
      degraded: monitors.degraded.count,
      paused: monitors.where(paused: true).count
    }
  end

  private

  def generate_keys
    self.api_key ||= "bl_beacon_#{SecureRandom.hex(16)}"
    self.ingest_key ||= "bl_beacon_ingest_#{SecureRandom.hex(16)}"
  end
end
