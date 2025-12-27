module Mcp
  module Tools
    class BeaconListMonitors < Base
      class << self
        def name
          "beacon_list_monitors"
        end

        def description
          "List all uptime monitors with their current status, response times, and uptime percentages"
        end

        def parameters
          {
            type: "object",
            properties: {
              status: {
                type: "string",
                enum: ["all", "healthy", "degraded", "down", "paused"],
                description: "Filter monitors by status"
              },
              check_type: {
                type: "string",
                enum: ["http", "ssl", "dns", "tcp", "ping"],
                description: "Filter by check type"
              }
            }
          }
        end
      end

      def execute(params)
        monitors = project.uptime_monitors.includes(:check_results)

        case params[:status]
        when "healthy" then monitors = monitors.healthy
        when "degraded" then monitors = monitors.degraded
        when "down" then monitors = monitors.down
        when "paused" then monitors = monitors.paused
        end

        monitors = monitors.where(check_type: params[:check_type]) if params[:check_type].present?

        monitors_data = monitors.map do |monitor|
          calculator = UptimeCalculator.new(monitor)

          {
            id: monitor.id,
            name: monitor.name,
            url: monitor.url || "#{monitor.host}:#{monitor.port}",
            check_type: monitor.check_type,
            status: monitor.status,
            last_check_at: monitor.last_check_at,
            response_time_ms: monitor.last_response_time,
            uptime_24h: calculator.uptime_percentage(24.hours),
            uptime_30d: calculator.uptime_percentage(30.days),
            enabled: monitor.enabled
          }
        end

        summary = {
          total: monitors.count,
          healthy: project.uptime_monitors.healthy.count,
          degraded: project.uptime_monitors.degraded.count,
          down: project.uptime_monitors.down.count,
          paused: project.uptime_monitors.paused.count
        }

        success(monitors: monitors_data, summary: summary)
      end
    end
  end
end
