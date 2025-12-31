class StatusPageMonitor < ApplicationRecord
  belongs_to :status_page
  belongs_to :uptime_monitor, foreign_key: :monitor_id

  validates :status_page_id, uniqueness: { scope: :monitor_id }

  scope :visible, -> { where(visible: true) }
  scope :ordered, -> { order(:position) }

  # Display name (falls back to monitor name)
  def name
    display_name.presence || uptime_monitor.name
  end

  # Current status from monitor
  def status
    uptime_monitor.status
  end

  # Uptime percentage
  def uptime(days: 90)
    uptime_monitor.uptime(period: days.days)
  end

  # Average response time
  def response_time
    uptime_monitor.average_response_time
  end
end
