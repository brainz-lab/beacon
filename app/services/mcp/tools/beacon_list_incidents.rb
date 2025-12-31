module Mcp
  module Tools
    class BeaconListIncidents < Base
      class << self
        def name
          "beacon_list_incidents"
        end

        def description
          "List incidents with their current status, timeline, and affected monitors"
        end

        def parameters
          {
            type: "object",
            properties: {
              status: {
                type: "string",
                enum: [ "active", "resolved", "all" ],
                description: "Filter by incident status (default: all)"
              },
              severity: {
                type: "string",
                enum: [ "critical", "major", "minor" ],
                description: "Filter by severity"
              },
              monitor_id: {
                type: "string",
                description: "Filter by specific monitor"
              },
              limit: {
                type: "integer",
                description: "Maximum number of incidents to return (default: 20)"
              }
            }
          }
        end
      end

      def execute(params)
        incidents = Incident.joins(:monitor)
                           .where(monitors: { project_id: project.id })
                           .includes(:monitor, :updates)

        case params[:status]
        when "active"
          incidents = incidents.active
        when "resolved"
          incidents = incidents.resolved
        end

        incidents = incidents.where(severity: params[:severity]) if params[:severity].present?
        incidents = incidents.where(monitor_id: params[:monitor_id]) if params[:monitor_id].present?

        limit = [ params[:limit] || 20, 100 ].min
        incidents = incidents.recent.limit(limit)

        success(
          incidents: incidents.map do |incident|
            {
              id: incident.id,
              title: incident.title,
              status: incident.status,
              severity: incident.severity,
              monitor: {
                id: incident.monitor_id,
                name: incident.monitor.name
              },
              started_at: incident.started_at,
              resolved_at: incident.resolved_at,
              duration: incident.duration_humanized,
              root_cause: incident.root_cause,
              updates_count: incident.updates.count,
              latest_update: incident.updates.last&.then do |u|
                {
                  status: u.status,
                  message: u.message,
                  created_at: u.created_at
                }
              end
            }
          end,
          summary: {
            active: Incident.joins(:monitor).where(monitors: { project_id: project.id }).active.count,
            resolved_today: Incident.joins(:monitor)
                                   .where(monitors: { project_id: project.id })
                                   .resolved
                                   .where("resolved_at >= ?", Time.current.beginning_of_day)
                                   .count
          }
        )
      end
    end
  end
end
