module Dashboard
  class SetupController < ApplicationController
    layout "dashboard"

    skip_before_action :set_current_project, raise: false

    def show
      @project = Project.first

      if @project
        redirect_to dashboard_root_path and return
      end

      @project = Project.new
    end

    def create
      @project = Project.new(project_params)
      @project.api_key ||= SecureRandom.hex(32)
      @project.ingest_key ||= SecureRandom.hex(32)

      if @project.save
        session[:project_id] = @project.id
        redirect_to dashboard_root_path, notice: "Beacon setup complete!"
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def project_params
      params.require(:project).permit(:name, :platform_project_id, :timezone)
    end
  end
end
