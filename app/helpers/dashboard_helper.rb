module DashboardHelper
  def status_dot_class(status)
    case status.to_s
    when "healthy", "operational", "up"
      "bg-success-500"
    when "degraded"
      "bg-warn-500"
    when "down", "major_outage"
      "bg-error-500"
    when "paused"
      "bg-ink-400"
    else
      "bg-ink-300"
    end
  end

  def status_badge_class(status)
    case status.to_s
    when "healthy", "operational", "up"
      "bg-success-100 text-success-800"
    when "degraded", "partial_outage"
      "bg-warn-100 text-warn-800"
    when "down", "major_outage"
      "bg-error-100 text-error-800"
    when "paused"
      "bg-cream-200 text-ink-600"
    else
      "bg-cream-100 text-ink-500"
    end
  end

  def severity_color_class(severity)
    case severity.to_s
    when "critical"
      "bg-error-500"
    when "major"
      "bg-warn-500"
    when "minor"
      "bg-info-500"
    else
      "bg-ink-400"
    end
  end

  def severity_badge_class(severity)
    case severity.to_s
    when "critical"
      "bg-error-100 text-error-800"
    when "major"
      "bg-warn-100 text-warn-800"
    when "minor"
      "bg-info-100 text-info-800"
    else
      "bg-cream-100 text-ink-500"
    end
  end

  def update_status_color(status)
    case status.to_s
    when "investigating"
      "bg-error-500"
    when "identified"
      "bg-warn-500"
    when "monitoring"
      "bg-info-500"
    when "resolved"
      "bg-success-500"
    else
      "bg-ink-400"
    end
  end

  def window_status_class(status)
    case status.to_s
    when "scheduled", "upcoming"
      "bg-info-100 text-info-800"
    when "active", "in_progress"
      "bg-warn-100 text-warn-800"
    when "completed", "past"
      "bg-cream-200 text-ink-600"
    when "cancelled"
      "bg-error-100 text-error-800"
    else
      "bg-cream-100 text-ink-500"
    end
  end
end
