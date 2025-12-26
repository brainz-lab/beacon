module Dashboard
  class IncidentUpdatesController < BaseController
    before_action :set_incident

    def create
      @incident.add_update(
        params[:status] || @incident.status,
        params[:message],
        user: current_user_name
      )

      respond_to do |format|
        format.html { redirect_to dashboard_incident_path(@incident), notice: "Update added" }
        format.turbo_stream do
          @updates = @incident.updates.chronological
          render turbo_stream: [
            turbo_stream.replace("incident_updates", partial: "dashboard/incidents/updates", locals: { updates: @updates }),
            turbo_stream.replace("update_form", partial: "dashboard/incidents/update_form", locals: { incident: @incident })
          ]
        end
      end
    end

    private

    def set_incident
      @incident = Incident.joins(:monitor)
                         .where(monitors: { project_id: current_project.id })
                         .find(params[:incident_id])
    end

    def current_user_name
      session[:user_name] || "dashboard"
    end
  end
end
