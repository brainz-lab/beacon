class StatusCalculator
  STATUSES = {
    operational: { priority: 0, label: "All Systems Operational", color: "#10B981" },
    degraded: { priority: 1, label: "Degraded Performance", color: "#F59E0B" },
    partial_outage: { priority: 2, label: "Partial Outage", color: "#F97316" },
    major_outage: { priority: 3, label: "Major Outage", color: "#EF4444" }
  }.freeze

  def initialize(status_page)
    @status_page = status_page
  end

  def overall_status
    @status_page.calculate_status
  end

  def status_info
    STATUSES[overall_status.to_sym] || STATUSES[:operational]
  end

  def component_statuses
    @status_page.status_page_monitors.includes(:uptime_monitor).map do |spm|
      {
        id: spm.uptime_monitor.id,
        name: spm.name,
        group: spm.group_name,
        status: spm.uptime_monitor.status,
        uptime: spm.uptime_monitor.uptime(period: 90.days),
        response_time: spm.uptime_monitor.average_response_time,
        last_check: spm.uptime_monitor.last_check_at
      }
    end
  end

  def groups_with_statuses
    @status_page.monitors_by_group.transform_values do |monitors|
      {
        monitors: monitors.map do |spm|
          {
            id: spm.uptime_monitor.id,
            name: spm.name,
            status: spm.uptime_monitor.status,
            uptime: spm.uptime_monitor.uptime(period: 90.days),
            response_time: spm.uptime_monitor.average_response_time
          }
        end,
        status: calculate_group_status(monitors)
      }
    end
  end

  def uptime_summary(days: 90)
    monitors = @status_page.uptime_monitors

    {
      overall: @status_page.overall_uptime(days: days),
      by_monitor: monitors.map do |m|
        {
          id: m.id,
          name: m.name,
          uptime: m.uptime(period: days.days)
        }
      end
    }
  end

  private

  def calculate_group_status(monitors)
    statuses = monitors.map { |spm| spm.uptime_monitor.status }

    if statuses.all? { |s| s == "up" }
      "operational"
    elsif statuses.all? { |s| s == "down" }
      "major_outage"
    elsif statuses.any? { |s| s == "down" }
      "partial_outage"
    elsif statuses.any? { |s| s == "degraded" }
      "degraded"
    else
      "operational"
    end
  end
end
