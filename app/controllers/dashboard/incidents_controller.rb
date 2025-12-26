module Dashboard
  class IncidentsController < BaseController
    before_action :set_incident, only: [:show, :edit, :update, :resolve]

    def index
      @incidents = Incident.joins(:monitor)
                          .where(monitors: { project_id: current_project.id })
                          .includes(:monitor, :updates)
                          .order(started_at: :desc)

      case params[:status]
      when "active"
        @incidents = @incidents.active
      when "resolved"
        @incidents = @incidents.resolved
      end

      @incidents = @incidents.where(severity: params[:severity]) if params[:severity].present?
      @incidents = @incidents.page(params[:page]).per(25) if @incidents.respond_to?(:page)
    end

    def show
      @updates = @incident.updates.chronological
      @monitor = @incident.monitor
    end

    def edit
    end

    def update
      if @incident.update(incident_params)
        redirect_to dashboard_incident_path(@incident),
                    notice: "Incident updated"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def resolve
      @incident.resolve!(notes: params[:resolution_notes])

      respond_to do |format|
        format.html { redirect_to dashboard_incident_path(@incident), notice: "Incident resolved" }
        format.turbo_stream
      end
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
  end
end
