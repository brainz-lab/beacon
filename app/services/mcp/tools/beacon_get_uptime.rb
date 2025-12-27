module Mcp
  module Tools
    class BeaconGetUptime < Base
      class << self
        def name
          "beacon_get_uptime"
        end

        def description
          "Get uptime statistics and response time data for monitors"
        end

        def parameters
          {
            type: "object",
            properties: {
              monitor_id: {
                type: "string",
                description: "Specific monitor ID (optional, returns all if not provided)"
              },
              period: {
                type: "string",
                enum: ["1h", "24h", "7d", "30d", "90d"],
                description: "Time period for statistics (default: 30d)"
              }
            }
          }
        end
      end

      def execute(params)
        period = parse_period(params[:period] || "30d")

        if params[:monitor_id].present?
          monitor = project.uptime_monitors.find_by(id: params[:monitor_id])
          return error("Monitor not found") unless monitor

          success(uptime: calculate_uptime(monitor, period))
        else
          monitors = project.uptime_monitors.enabled

          success(
            overall_uptime: calculate_overall_uptime(monitors, period),
            monitors: monitors.map { |m| calculate_uptime(m, period) }
          )
        end
      end

      private

      def parse_period(period_str)
        case period_str
        when "1h" then 1.hour
        when "24h" then 24.hours
        when "7d" then 7.days
        when "30d" then 30.days
        when "90d" then 90.days
        else 30.days
        end
      end

      def calculate_uptime(monitor, period)
        calculator = UptimeCalculator.new(monitor)

        {
          monitor_id: monitor.id,
          monitor_name: monitor.name,
          uptime_percentage: calculator.uptime_percentage(period),
          total_checks: calculator.total_checks(period),
          successful_checks: calculator.successful_checks(period),
          failed_checks: calculator.failed_checks(period),
          average_response_time: calculator.average_response_time(period),
          min_response_time: calculator.min_response_time(period),
          max_response_time: calculator.max_response_time(period),
          p95_response_time: calculator.percentile_response_time(period, 95),
          p99_response_time: calculator.percentile_response_time(period, 99),
          downtime_minutes: calculator.downtime_minutes(period),
          incidents_count: monitor.incidents.where("started_at >= ?", period.ago).count
        }
      end

      def calculate_overall_uptime(monitors, period)
        return 100.0 if monitors.empty?

        uptimes = monitors.map do |m|
          UptimeCalculator.new(m).uptime_percentage(period)
        end

        (uptimes.sum / uptimes.size).round(2)
      end
    end
  end
end
