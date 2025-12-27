module Dashboard
  class OverviewController < BaseController
    before_action :require_project!

    def index
      @monitors = @project.uptime_monitors.includes(:check_results).order(:name)
      @active_incidents = Incident.joins(:uptime_monitor)
                                  .where(uptime_monitors: { project_id: @project.id })
                                  .active
                                  .includes(:uptime_monitor, :updates)
                                  .recent

      @maintenance_windows = @project.maintenance_windows.upcoming.limit(5)

      # Calculate summary stats
      @stats = {
        total_monitors: @monitors.count,
        healthy: @monitors.up.count,
        degraded: @monitors.degraded.count,
        down: @monitors.down.count,
        paused: @monitors.paused.count,
        active_incidents: @active_incidents.count,
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
