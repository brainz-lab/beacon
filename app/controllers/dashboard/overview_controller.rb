module Dashboard
  class OverviewController < BaseController
    def index
      @monitors = current_project.monitors.includes(:check_results).order(:name)
      @active_incidents = Incident.joins(:monitor)
                                  .where(monitors: { project_id: current_project.id })
                                  .active
                                  .includes(:monitor, :updates)
                                  .recent

      @maintenance_windows = current_project.maintenance_windows.upcoming.limit(5)

      # Calculate summary stats
      @stats = {
        total_monitors: @monitors.count,
        healthy: @monitors.healthy.count,
        degraded: @monitors.degraded.count,
        down: @monitors.down.count,
        paused: @monitors.paused.count,
        active_incidents: @active_incidents.count,
        overall_uptime: calculate_overall_uptime
      }

      # Recent checks for activity feed
      @recent_checks = CheckResult.joins(:monitor)
                                  .where(monitors: { project_id: current_project.id })
                                  .where("check_results.checked_at > ?", 1.hour.ago)
                                  .order(checked_at: :desc)
                                  .limit(20)
    end

    private

    def calculate_overall_uptime
      monitors = current_project.monitors.enabled
      return 100.0 if monitors.empty?

      uptimes = monitors.map do |m|
        UptimeCalculator.new(m).uptime_percentage(30.days)
      end

      (uptimes.sum / uptimes.size).round(2)
    end
  end
end
