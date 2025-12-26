module Mcp
  module Tools
    class BeaconCreateMonitor < Base
      class << self
        def name
          "beacon_create_monitor"
        end

        def description
          "Create a new uptime monitor to track an endpoint, API, or service"
        end

        def parameters
          {
            type: "object",
            required: ["name"],
            properties: {
              name: {
                type: "string",
                description: "Name for this monitor"
              },
              url: {
                type: "string",
                description: "URL to monitor (for HTTP checks)"
              },
              host: {
                type: "string",
                description: "Host to monitor (for TCP, DNS, Ping checks)"
              },
              port: {
                type: "integer",
                description: "Port to check (for TCP checks)"
              },
              check_type: {
                type: "string",
                enum: ["http", "ssl", "dns", "tcp", "ping"],
                description: "Type of check to perform (default: http)"
              },
              interval: {
                type: "integer",
                description: "Check interval in seconds (default: 60)"
              },
              expected_status: {
                type: "integer",
                description: "Expected HTTP status code (default: 200)"
              },
              expected_body: {
                type: "string",
                description: "Text that must appear in response body"
              },
              regions: {
                type: "array",
                items: { type: "string" },
                description: "Regions to check from (default: ['nyc'])"
              }
            }
          }
        end
      end

      def execute(params)
        monitor = project.monitors.new(
          name: params[:name],
          url: params[:url],
          host: params[:host],
          port: params[:port] || 443,
          check_type: params[:check_type] || "http",
          interval: params[:interval] || 60,
          timeout: 30000,
          expected_status: params[:expected_status] || 200,
          expected_body: params[:expected_body],
          regions: params[:regions] || ["nyc"],
          enabled: true
        )

        if monitor.save
          # Schedule first check
          ExecuteCheckJob.perform_later(monitor.id)

          success(
            message: "Monitor created successfully",
            monitor: {
              id: monitor.id,
              name: monitor.name,
              url: monitor.url || "#{monitor.host}:#{monitor.port}",
              check_type: monitor.check_type,
              interval: monitor.interval,
              status: "pending"
            }
          )
        else
          error("Failed to create monitor: #{monitor.errors.full_messages.join(', ')}")
        end
      end
    end
  end
end
