class Monitor < ApplicationRecord
  belongs_to :project

  has_many :check_results, dependent: :destroy
  has_many :incidents, dependent: :destroy
  has_many :status_page_monitors, dependent: :destroy
  has_many :status_pages, through: :status_page_monitors
  has_many :alert_rules, dependent: :destroy
  has_one :ssl_certificate, dependent: :destroy

  validates :name, presence: true
  validates :monitor_type, presence: true, inclusion: { in: %w[http tcp dns ssl ping] }
  validates :url, presence: true, if: -> { monitor_type == "http" || monitor_type == "ssl" }
  validates :host, presence: true, if: -> { monitor_type.in?(%w[tcp dns ping]) }
  validates :port, presence: true, if: -> { monitor_type == "tcp" }
  validates :interval_seconds, numericality: { greater_than_or_equal_to: 30 }

  scope :enabled, -> { where(enabled: true, paused: false) }
  scope :paused, -> { where(paused: true) }
  scope :due_for_check, ->(region = nil) {
    query = enabled.where("last_check_at IS NULL OR last_check_at < NOW() - (interval_seconds * interval '1 second')")
    region ? query.where("? = ANY(regions)", region) : query
  }
  scope :by_status, ->(status) { where(status: status) }
  scope :up, -> { by_status("up") }
  scope :down, -> { by_status("down") }
  scope :degraded, -> { by_status("degraded") }

  enum :status, { unknown: "unknown", up: "up", down: "down", degraded: "degraded" }, prefix: true

  # Perform a check using the appropriate checker
  def check!(region: Beacon.current_region)
    checker = checker_class.new(self, region: region)
    result = checker.check

    process_result(result)
    result
  end

  # Calculate uptime for a period
  def uptime(period: 30.days)
    UptimeCalculator.new(self, period: period).calculate
  end

  # Average response time for a period
  def average_response_time(period: 24.hours)
    check_results
      .where("checked_at > ?", period.ago)
      .where(status: "up")
      .average(:response_time_ms)
      &.round || 0
  end

  # Response time series for charts
  def response_time_series(period: 24.hours, interval: "1 hour")
    check_results
      .where("checked_at > ?", period.ago)
      .where(status: "up")
      .group("time_bucket('#{interval}', checked_at)")
      .average(:response_time_ms)
      .transform_values { |v| v&.round }
  end

  # Recent checks
  def recent_checks(limit: 20)
    check_results.order(checked_at: :desc).limit(limit)
  end

  # Active incident
  def active_incident
    incidents.active.order(started_at: :desc).first
  end

  # Target URL or host for display
  def target
    url.presence || "#{host}:#{port}"
  end

  private

  def checker_class
    case monitor_type
    when "http" then Checkers::HTTPChecker
    when "tcp" then Checkers::TCPChecker
    when "dns" then Checkers::DNSChecker
    when "ssl" then Checkers::SSLChecker
    when "ping" then Checkers::PingChecker
    else
      raise "Unknown monitor type: #{monitor_type}"
    end
  end

  def process_result(result)
    previous_status = status

    if result.success?
      self.consecutive_successes += 1
      self.consecutive_failures = 0
      self.last_up_at = Time.current

      if consecutive_successes >= recovery_threshold
        self.status = "up"
        resolve_active_incident if previous_status != "up"
      end
    else
      self.consecutive_failures += 1
      self.consecutive_successes = 0
      self.last_down_at = Time.current

      if consecutive_failures >= confirmation_threshold
        self.status = "down"
        create_incident if previous_status == "up"
      end
    end

    self.last_check_at = Time.current
    save!

    # Broadcast status change via ActionCable
    broadcast_status if saved_change_to_status?

    # Update status pages
    update_status_pages if saved_change_to_status?
  end

  def create_incident
    incidents.create!(
      title: "#{name} is down",
      status: "investigating",
      severity: "major",
      started_at: last_down_at,
      affected_regions: regions
    )
  end

  def resolve_active_incident
    incidents.active.find_each do |incident|
      incident.resolve!
    end
  end

  def broadcast_status
    ActionCable.server.broadcast(
      "monitor_#{id}",
      {
        id: id,
        status: status,
        last_check_at: last_check_at,
        consecutive_failures: consecutive_failures,
        consecutive_successes: consecutive_successes
      }
    )
  end

  def update_status_pages
    status_pages.each(&:update_status!)
  end
end
