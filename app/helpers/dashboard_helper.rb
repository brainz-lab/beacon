module DashboardHelper
  def status_dot_class(status)
    case status.to_s
    when "healthy", "operational", "up"
      "bg-green-500"
    when "degraded"
      "bg-yellow-500"
    when "down", "major_outage"
      "bg-red-500"
    when "paused"
      "bg-gray-400"
    else
      "bg-gray-300"
    end
  end

  def status_badge_class(status)
    case status.to_s
    when "healthy", "operational", "up"
      "bg-green-100 text-green-800"
    when "degraded", "partial_outage"
      "bg-yellow-100 text-yellow-800"
    when "down", "major_outage"
      "bg-red-100 text-red-800"
    when "paused"
      "bg-gray-100 text-gray-800"
    else
      "bg-gray-100 text-gray-600"
    end
  end

  def severity_color_class(severity)
    case severity.to_s
    when "critical"
      "bg-red-500"
    when "major"
      "bg-orange-500"
    when "minor"
      "bg-yellow-500"
    else
      "bg-gray-400"
    end
  end

  def severity_badge_class(severity)
    case severity.to_s
    when "critical"
      "bg-red-100 text-red-800"
    when "major"
      "bg-orange-100 text-orange-800"
    when "minor"
      "bg-yellow-100 text-yellow-800"
    else
      "bg-gray-100 text-gray-600"
    end
  end

  def update_status_color(status)
    case status.to_s
    when "investigating"
      "bg-red-500"
    when "identified"
      "bg-orange-500"
    when "monitoring"
      "bg-yellow-500"
    when "resolved"
      "bg-green-500"
    else
      "bg-gray-400"
    end
  end

  def window_status_class(status)
    case status.to_s
    when "scheduled", "upcoming"
      "bg-blue-100 text-blue-800"
    when "active", "in_progress"
      "bg-yellow-100 text-yellow-800"
    when "completed", "past"
      "bg-gray-100 text-gray-800"
    when "cancelled"
      "bg-red-100 text-red-800"
    else
      "bg-gray-100 text-gray-600"
    end
  end
end
