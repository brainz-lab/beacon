module Dashboard
  class OverviewController < BaseController
    before_action :require_project!

    def index
      @monitors = @project.uptime_monitors.includes(:check_results).order(:name).load
      @active_incidents = Incident.joins(:uptime_monitor)
                                  .where(uptime_monitors: { project_id: @project.id })
                                  .active
                                  .includes(:uptime_monitor, :updates)
                                  .recent

      @maintenance_windows = @project.maintenance_windows.upcoming.limit(5)

      # Calculate summary stats using in-memory counting to avoid N+1 queries
      # Group by status once and count each status
      status_counts = @monitors.group_by(&:status).transform_values(&:size)
      @stats = {
        total_monitors: @monitors.size,
        healthy: status_counts["up"] || 0,
        degraded: status_counts["degraded"] || 0,
        down: status_counts["down"] || 0,
        paused: @monitors.count(&:paused?),
        active_incidents: @active_incidents.size,
        overall_uptime: calculate_overall_uptime
      }

      # Recent checks for activity feed
      @recent_checks = CheckResult.joins(:uptime_monitor)
                                  .where(uptime_monitors: { project_id: @project.id })
                                  .where("check_results.checked_at > ?", 1.hour.ago)
                                  .order(checked_at: :desc)
                                  .limit(20)
    end

    private

    def calculate_overall_uptime
      monitors = @project.uptime_monitors.enabled
      return 100.0 if monitors.empty?

      uptimes = monitors.map do |m|
        UptimeCalculator.new(m).uptime_percentage(30.days)
      end

      (uptimes.sum / uptimes.size).round(2)
    end
  end
end
