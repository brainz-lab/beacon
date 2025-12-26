class CheckResult < ApplicationRecord
  # Note: This is a TimescaleDB hypertable, so we use raw SQL for some operations
  self.primary_key = "id"

  belongs_to :monitor

  validates :checked_at, presence: true
  validates :region, presence: true
  validates :status, presence: true

  scope :recent, -> { order(checked_at: :desc) }
  scope :successful, -> { where(status: "up") }
  scope :failed, -> { where(status: "down") }
  scope :in_region, ->(region) { where(region: region) }
  scope :since, ->(time) { where("checked_at >= ?", time) }

  def success?
    status == "up"
  end

  def failed?
    status == "down"
  end

  # Timing breakdown for display
  def timing_breakdown
    {
      dns: dns_time_ms,
      connect: connect_time_ms,
      tls: tls_time_ms,
      ttfb: ttfb_ms,
      total: response_time_ms
    }.compact
  end

  # Human-readable error
  def error_description
    case error_type
    when "timeout" then "Request timed out"
    when "dns_error" then "DNS resolution failed"
    when "ssl_error" then "SSL/TLS error"
    when "connection_refused" then "Connection refused"
    when "ping_failed" then "Host unreachable"
    else
      error_message
    end
  end
end
