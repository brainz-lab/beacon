module ApplicationHelper
  def status_color(status)
    case status.to_s
    when "up", "operational"
      "text-green-500"
    when "down", "major_outage"
      "text-red-500"
    when "degraded", "partial_outage"
      "text-yellow-500"
    else
      "text-gray-500"
    end
  end

  def status_bg_color(status)
    case status.to_s
    when "up", "operational"
      "bg-green-500"
    when "down", "major_outage"
      "bg-red-500"
    when "degraded", "partial_outage"
      "bg-yellow-500"
    else
      "bg-gray-500"
    end
  end

  def status_label(status)
    case status.to_s
    when "up" then "Up"
    when "down" then "Down"
    when "degraded" then "Degraded"
    when "unknown" then "Unknown"
    when "operational" then "Operational"
    when "partial_outage" then "Partial Outage"
    when "major_outage" then "Major Outage"
    else status.to_s.humanize
    end
  end

  def uptime_color(percentage)
    case percentage
    when 99.9..100 then "text-green-500"
    when 99..99.9 then "text-yellow-500"
    when 95..99 then "text-orange-500"
    else "text-red-500"
    end
  end

  def format_duration(seconds)
    return "N/A" unless seconds

    parts = []
    days = seconds / 86400
    hours = (seconds % 86400) / 3600
    minutes = (seconds % 3600) / 60
    secs = seconds % 60

    parts << "#{days}d" if days > 0
    parts << "#{hours}h" if hours > 0
    parts << "#{minutes}m" if minutes > 0
    parts << "#{secs}s" if secs > 0 && days == 0 && hours == 0

    parts.empty? ? "0s" : parts.join(" ")
  end

  def format_response_time(ms)
    return "N/A" unless ms
    "#{ms.round}ms"
  end
end
