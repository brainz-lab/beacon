# frozen_string_literal: true

module DashboardHelper
  # Icon helpers - inline SVG to avoid partial render overhead
  ICONS = {
    overview: '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"/></svg>',
    monitors: '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>',
    incidents: '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>',
    status_pages: '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>',
    maintenance: '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/></svg>',
    setup: '<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>'
  }.freeze

  def icon(name)
    ICONS[name.to_sym]&.html_safe
  end

  # Navigation helpers for sidebar
  def nav_active?(controller)
    controller_name == controller.to_s
  end

  def nav_link_class(controller)
    nav_active?(controller) ? "nav-item active" : "nav-item"
  end

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
