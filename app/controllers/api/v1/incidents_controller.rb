module Api
  module V1
    class IncidentsController < BaseController
      before_action :set_incident, only: [:show, :update]

      # GET /api/v1/incidents
      def index
        incidents = Incident.joins(:monitor)
                           .where(monitors: { project_id: current_project.id })
                           .includes(:monitor, :updates)

        # Filter by status
        case params[:status]
        when "active"
          incidents = incidents.active
        when "resolved"
          incidents = incidents.resolved
        end

        # Filter by severity
        incidents = incidents.where(severity: params[:severity]) if params[:severity].present?

        # Filter by monitor
        if params[:monitor_id].present?
          incidents = incidents.where(monitor_id: params[:monitor_id])
        end

        incidents = incidents.recent.limit(params.fetch(:limit, 50).to_i)

        render json: {
          incidents: incidents.map { |i| incident_json(i) },
          summary: {
            active: Incident.joins(:monitor).where(monitors: { project_id: current_project.id }).active.count,
            resolved_today: Incident.joins(:monitor).where(monitors: { project_id: current_project.id }).resolved.where("resolved_at >= ?", Time.current.beginning_of_day).count
          }
        }
      end

      # GET /api/v1/incidents/:id
      def show
        render json: incident_json(@incident, detailed: true)
      end

      # PATCH /api/v1/incidents/:id
      def update
        if params[:resolve] == true
          @incident.resolve!(notes: params[:resolution_notes])
        elsif params[:status].present? && params[:message].present?
          @incident.add_update(
            params[:status],
            params[:message],
            user: params[:user] || "api"
          )
        else
          @incident.update!(incident_params)
        end

        render json: incident_json(@incident, detailed: true)
      end

      private

      def set_incident
        @incident = Incident.joins(:monitor)
                           .where(monitors: { project_id: current_project.id })
                           .find(params[:id])
      end

      def incident_params
        params.require(:incident).permit(
          :title, :severity, :root_cause, :resolution_notes
        )
      end

      def incident_json(incident, detailed: false)
        data = {
          id: incident.id,
          title: incident.title,
          status: incident.status,
          severity: incident.severity,
          started_at: incident.started_at,
          resolved_at: incident.resolved_at,
          duration: incident.duration_humanized,
          monitor: {
            id: incident.monitor_id,
            name: incident.monitor.name
          }
        }

        if detailed
          data.merge!(
            identified_at: incident.identified_at,
            affected_regions: incident.affected_regions,
            uptime_impact: incident.uptime_impact,
            root_cause: incident.root_cause,
            resolution_notes: incident.resolution_notes,
            notified: incident.notified,
            updates: incident.updates.chronological.map { |u| update_json(u) },
            created_at: incident.created_at,
            updated_at: incident.updated_at
          )
        end

        data
      end

      def update_json(update)
        {
          id: update.id,
          status: update.status,
          message: update.message,
          created_by: update.created_by,
          created_at: update.created_at
        }
      end
    end
  end
end
