# AlertEvaluator - Evaluates alert rules against monitor check results
class AlertEvaluator
  def initialize(monitor)
    @monitor = monitor
  end

  def evaluate(check_result)
    return unless @monitor.alert_rules.any?

    @monitor.alert_rules.enabled.each do |rule|
      evaluate_rule(rule, check_result)
    end
  end

  private

  def evaluate_rule(rule, check_result)
    triggered = case rule.condition_type
    when "response_time"
      evaluate_response_time(rule, check_result)
    when "status_code"
      evaluate_status_code(rule, check_result)
    when "consecutive_failures"
      evaluate_consecutive_failures(rule)
    when "uptime_percentage"
      evaluate_uptime_percentage(rule)
    else
      false
    end

    if triggered
      trigger_alert(rule)
    else
      clear_alert(rule) if rule.last_triggered_at.present?
    end
  end

  def evaluate_response_time(rule, check_result)
    return false unless check_result.response_time

    compare(check_result.response_time, rule.comparison, rule.threshold)
  end

  def evaluate_status_code(rule, check_result)
    return false unless check_result.status_code

    compare(check_result.status_code, rule.comparison, rule.threshold.to_i)
  end

  def evaluate_consecutive_failures(rule)
    # Check if we have N consecutive failures
    recent_checks = @monitor.check_results
                           .order(checked_at: :desc)
                           .limit(rule.threshold.to_i)

    return false if recent_checks.count < rule.threshold.to_i

    recent_checks.all? { |c| c.status == "down" || c.status == "failure" }
  end

  def evaluate_uptime_percentage(rule)
    period = (rule.duration_minutes || 60).minutes
    calculator = UptimeCalculator.new(@monitor)
    uptime = calculator.uptime_percentage(period)

    compare(uptime, rule.comparison, rule.threshold)
  end

  def compare(value, comparison, threshold)
    case comparison
    when "gt", ">" then value > threshold
    when "gte", ">=" then value >= threshold
    when "lt", "<" then value < threshold
    when "lte", "<=" then value <= threshold
    when "eq", "==" then value == threshold
    when "ne", "!=" then value != threshold
    else false
    end
  end

  def trigger_alert(rule)
    # Check if already recently triggered (within duration window)
    if rule.last_triggered_at.present? && rule.last_triggered_at > (rule.duration_minutes || 5).minutes.ago
      return
    end

    rule.update!(last_triggered_at: Time.current)

    # Send to configured channels
    rule.notify_channels.each do |channel|
      case channel
      when "signal"
        SignalClient.trigger_alert(
          source: "beacon",
          title: "[Beacon] Alert: #{rule.name}",
          severity: severity_for_rule(rule),
          data: {
            type: "alert_rule_triggered",
            rule_id: rule.id,
            rule_name: rule.name,
            condition: "#{rule.condition_type} #{rule.comparison} #{rule.threshold}",
            monitor_id: @monitor.id,
            monitor_name: @monitor.name
          }
        )
      when "email"
        # Would send email notification
        Rails.logger.info "[AlertEvaluator] Would send email for rule #{rule.id}"
      when "webhook"
        # Would send webhook notification
        Rails.logger.info "[AlertEvaluator] Would send webhook for rule #{rule.id}"
      end
    end
  end

  def clear_alert(rule)
    # Only clear if duration has passed since last trigger
    return unless rule.last_triggered_at.present?
    return if rule.last_triggered_at > 5.minutes.ago

    rule.update!(last_triggered_at: nil)

    if rule.notify_channels.include?("signal")
      SignalClient.resolve_alert(
        source: "beacon",
        title: "[Beacon] Alert: #{rule.name}",
        data: {
          type: "alert_rule_cleared",
          rule_id: rule.id,
          monitor_id: @monitor.id
        }
      )
    end
  end

  def severity_for_rule(rule)
    case rule.condition_type
    when "consecutive_failures"
      rule.threshold.to_i >= 5 ? "critical" : "high"
    when "response_time"
      rule.threshold.to_i >= 5000 ? "high" : "medium"
    when "uptime_percentage"
      rule.threshold.to_f < 95 ? "critical" : "high"
    else
      "medium"
    end
  end
end
