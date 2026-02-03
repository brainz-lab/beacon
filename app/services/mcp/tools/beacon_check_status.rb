module MCP
  module Tools
    class BeaconCheckStatus < Base
      class << self
        def name
          "beacon_check_status"
        end

        def description
          "Get detailed status of a specific monitor including recent checks and incidents"
        end

        def parameters
          {
            type: "object",
            properties: {
              monitor_id: {
                type: "string",
                description: "The monitor ID to check"
              },
              monitor_name: {
                type: "string",
                description: "The monitor name to search for (if ID not provided)"
              }
            }
          }
        end
      end

      def execute(params)
        monitor = find_monitor(params)
        return error("Monitor not found") unless monitor

        calculator = UptimeCalculator.new(monitor)
        recent_checks = monitor.check_results.order(checked_at: :desc).limit(10)
        recent_incidents = monitor.incidents.recent.limit(5)

        success(
          monitor: {
            id: monitor.id,
            name: monitor.name,
            url: monitor.url || "#{monitor.host}:#{monitor.port}",
            check_type: monitor.check_type,
            status: monitor.status,
            enabled: monitor.enabled,
            interval: monitor.interval,
            regions: monitor.regions
          },
          current_status: {
            status: monitor.status,
            last_check_at: monitor.last_check_at,
            response_time_ms: monitor.last_response_time,
            status_code: recent_checks.first&.status_code
          },
          uptime: {
            last_hour: calculator.uptime_percentage(1.hour),
            last_24h: calculator.uptime_percentage(24.hours),
            last_7d: calculator.uptime_percentage(7.days),
            last_30d: calculator.uptime_percentage(30.days)
          },
          performance: {
            avg_response_24h: calculator.average_response_time(24.hours),
            avg_response_7d: calculator.average_response_time(7.days),
            p95_response_24h: calculator.percentile_response_time(24.hours, 95),
            p99_response_24h: calculator.percentile_response_time(24.hours, 99)
          },
          recent_checks: recent_checks.map do |check|
            {
              checked_at: check.checked_at,
              status: check.status,
              response_time: check.response_time,
              status_code: check.status_code,
              region: check.region,
              error: check.error_message
            }
          end,
          recent_incidents: recent_incidents.map do |incident|
            {
              id: incident.id,
              title: incident.title,
              status: incident.status,
              severity: incident.severity,
              started_at: incident.started_at,
              resolved_at: incident.resolved_at,
              duration: incident.duration_humanized
            }
          end
        )
      end

      private

      def find_monitor(params)
        if params[:monitor_id].present?
          project.uptime_monitors.find_by(id: params[:monitor_id])
        elsif params[:monitor_name].present?
          project.uptime_monitors.find_by("name ILIKE ?", "%#{params[:monitor_name]}%")
        end
      end
    end
  end
end
