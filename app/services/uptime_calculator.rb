class UptimeCalculator
  def initialize(monitor, period: 30.days)
    @monitor = monitor
    @period = period
  end

  def calculate
    uptime_percentage(@period)
  end

  def uptime_percentage(period = @period)
    results = checks_in_period(period).group(:status).count
    total = results.values.sum
    return 100.0 if total.zero?

    up_count = results["up"] || results["success"] || 0
    ((up_count.to_f / total) * 100).round(2)
  end

  def total_checks(period = @period)
    checks_in_period(period).count
  end

  def successful_checks(period = @period)
    checks_in_period(period).where(status: ["up", "success"]).count
  end

  def failed_checks(period = @period)
    checks_in_period(period).where(status: ["down", "failure"]).count
  end

  def average_response_time(period = @period)
    checks_in_period(period).average(:response_time)&.round(2) || 0
  end

  def min_response_time(period = @period)
    checks_in_period(period).minimum(:response_time) || 0
  end

  def max_response_time(period = @period)
    checks_in_period(period).maximum(:response_time) || 0
  end

  def percentile_response_time(period, percentile)
    times = checks_in_period(period).pluck(:response_time).compact.sort
    return 0 if times.empty?

    index = (percentile.to_f / 100 * times.length).ceil - 1
    times[[index, 0].max]
  end

  def downtime_minutes(period = @period)
    (downtime_seconds_for(period) / 60.0).round
  end

  private

  def checks_in_period(period)
    @monitor.check_results.where("checked_at > ?", period.ago)
  end

  def downtime_seconds_for(period)
    total_period = period.to_i
    uptime_pct = uptime_percentage(period)
    ((100 - uptime_pct) / 100 * total_period).round
  end

  def daily_breakdown
    @monitor.check_results
            .where("checked_at > ?", @period.ago)
            .group("DATE(checked_at)")
            .group(:status)
            .count
  end

  # Returns array of daily uptime data for visualization
  def uptime_bars(days: 90)
    days_data = []

    (0...days).each do |i|
      date = i.days.ago.to_date
      results = @monitor.check_results
                        .where("DATE(checked_at) = ?", date)
                        .group(:status)
                        .count

      total = results.values.sum

      if total.zero?
        days_data << {
          date: date,
          uptime: nil,
          status: "no_data",
          checks: 0
        }
      else
        up_count = results["up"] || 0
        uptime = ((up_count.to_f / total) * 100).round(2)

        days_data << {
          date: date,
          uptime: uptime,
          status: uptime_status(uptime),
          checks: total
        }
      end
    end

    days_data.reverse
  end

  # Calculate downtime in seconds for a period
  def downtime_seconds
    downtime_seconds_for(@period)
  end

  # Human-readable downtime
  def downtime_humanized
    seconds = downtime_seconds
    return "0s" if seconds <= 0

    parts = []
    days = seconds / 86400
    hours = (seconds % 86400) / 3600
    minutes = (seconds % 3600) / 60
    secs = seconds % 60

    parts << "#{days}d" if days > 0
    parts << "#{hours}h" if hours > 0
    parts << "#{minutes}m" if minutes > 0
    parts << "#{secs}s" if secs > 0 && days == 0 && hours == 0

    parts.join(" ")
  end

  private

  def uptime_status(uptime)
    case uptime
    when 100 then "operational"
    when 99..100 then "degraded"
    when 95..99 then "partial_outage"
    else "major_outage"
    end
  end
end
