module Api
  module V1
    class IncidentUpdatesController < Api::V1::BaseController
      before_action :set_incident

      # GET /api/v1/incidents/:incident_id/updates
      def index
        updates = @incident.updates.chronological

        render json: {
          updates: updates.map { |u| update_json(u) }
        }
      end

      # POST /api/v1/incidents/:incident_id/updates
      def create
        @incident.add_update(
          params[:status] || @incident.status,
          params[:message],
          user: params[:user] || "api"
        )

        render json: {
          success: true,
          incident: {
            id: @incident.id,
            status: @incident.status
          },
          update: update_json(@incident.updates.last)
        }, status: :created
      end

      private

      def set_incident
        @incident = Incident.joins(:monitor)
                           .where(monitors: { project_id: current_project.id })
                           .find(params[:incident_id])
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
