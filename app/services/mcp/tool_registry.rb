module MCP
  class ToolRegistry
    TOOLS = [
      Tools::BeaconListMonitors,
      Tools::BeaconCheckStatus,
      Tools::BeaconCreateMonitor,
      Tools::BeaconGetUptime,
      Tools::BeaconListIncidents
    ].freeze

    class << self
      def all
        TOOLS
      end

      def find(name)
        TOOLS.find { |tool| tool.name == name }
      end

      def schema
        TOOLS.map do |tool|
          {
            name: tool.name,
            description: tool.description,
            inputSchema: tool.parameters
          }
        end
      end

      def call(name, params, project:)
        tool = find(name)
        raise ArgumentError, "Unknown tool: #{name}" unless tool

        tool.call(params, project: project)
      end
    end
  end
end
