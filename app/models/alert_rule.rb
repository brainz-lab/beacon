class AlertRule < ApplicationRecord
  belongs_to :monitor

  validates :name, presence: true
  validates :condition_type, presence: true, inclusion: {
    in: %w[status_change response_time ssl_expiry consecutive_failures status_code uptime_percentage]
  }

  scope :enabled, -> { where(enabled: true) }
  scope :by_type, ->(type) { where(condition_type: type) }

  CONDITION_TYPES = {
    "status_change" => "Status Change",
    "response_time" => "Response Time",
    "ssl_expiry" => "SSL Expiry",
    "consecutive_failures" => "Consecutive Failures",
    "status_code" => "HTTP Status Code",
    "uptime_percentage" => "Uptime Percentage"
  }.freeze

  # Check if the rule is triggered
  def triggered?(check_result = nil)
    case condition_type
    when "status_change"
      check_status_change(check_result)
    when "response_time"
      check_response_time(check_result)
    when "ssl_expiry"
      check_ssl_expiry
    else
      false
    end
  end

  # Get the condition description
  def condition_description
    case condition_type
    when "status_change"
      from = condition_config["from"] || "any"
      to = condition_config["to"] || "down"
      "Status changes from #{from} to #{to}"
    when "response_time"
      operator = condition_config["operator"] || "gt"
      value = condition_config["value"] || 1000
      op_text = operator == "gt" ? "exceeds" : "is below"
      "Response time #{op_text} #{value}ms"
    when "ssl_expiry"
      days = condition_config["days_before"] || 30
      "SSL certificate expires within #{days} days"
    end
  end

  private

  def check_status_change(check_result)
    return false unless check_result

    expected_from = condition_config["from"]
    expected_to = condition_config["to"] || "down"

    # Check if monitor transitioned to expected status
    monitor.status == expected_to &&
      (expected_from.nil? || monitor.status_before_last_save == expected_from)
  end

  def check_response_time(check_result)
    return false unless check_result&.response_time_ms

    operator = condition_config["operator"] || "gt"
    value = condition_config["value"] || 1000

    case operator
    when "gt" then check_result.response_time_ms > value
    when "lt" then check_result.response_time_ms < value
    when "gte" then check_result.response_time_ms >= value
    when "lte" then check_result.response_time_ms <= value
    else false
    end
  end

  def check_ssl_expiry
    return false unless monitor.ssl_expiry_at

    days_before = condition_config["days_before"] || 30
    monitor.ssl_expiry_at < days_before.days.from_now
  end
end
