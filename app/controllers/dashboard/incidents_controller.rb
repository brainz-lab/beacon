module Dashboard
  class IncidentsController < BaseController
    before_action :require_project!
    before_action :set_incident, only: [ :show, :edit, :update, :destroy, :resolve ]

    def index
      @incidents = Incident.joins(:uptime_monitor)
                           .where(uptime_monitors: { project_id: @project.id })
                           .includes(:uptime_monitor, :updates)
                           .order(started_at: :desc)

      case params[:status]
      when "active" then @incidents = @incidents.active
      when "resolved" then @incidents = @incidents.resolved
      end
    end

    def show
      @updates = @incident.updates.order(created_at: :desc)
      @monitor = @incident.uptime_monitor
    end

    def new
      @incident = Incident.new(
        started_at: Time.current,
        status: "investigating",
        severity: "major"
      )
      @monitors = @project.uptime_monitors.order(:name)
    end

    def create
      @incident = Incident.new(incident_params)

      if @incident.save
        redirect_to dashboard_project_incident_path(@project, @incident),
                    notice: "Incident created"
      else
        @monitors = @project.uptime_monitors.order(:name)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @monitors = @project.uptime_monitors.order(:name)
    end

    def update
      if @incident.update(incident_params)
        redirect_to dashboard_project_incident_path(@project, @incident),
                    notice: "Incident updated"
      else
        @monitors = @project.uptime_monitors.order(:name)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @incident.destroy!
      redirect_to dashboard_project_incidents_path(@project),
                  notice: "Incident deleted"
    end

    def resolve
      @incident.resolve!(notes: params[:notes])
      redirect_to dashboard_project_incident_path(@project, @incident),
                  notice: "Incident resolved"
    end

    private

    def set_incident
      @incident = Incident.joins(:uptime_monitor)
                          .where(uptime_monitors: { project_id: @project.id })
                          .find(params[:id])
    end

    def incident_params
      params.require(:incident).permit(
        :monitor_id, :title, :severity, :status,
        :started_at, :root_cause, :resolution_notes
      )
    end
  end
end
