# frozen_string_literal: true

module Dashboard
  class ProjectsController < ApplicationController
    before_action :authenticate_via_sso!
    before_action :set_project, only: [ :show, :settings ]

    layout "dashboard"

    def index
      @projects = Project.order(created_at: :desc)
    end

    def show
      redirect_to dashboard_project_overview_path(@project)
    end

    def new
      @project = Project.new
    end

    def create
      @project = Project.new(project_params)

      if @project.save
        redirect_to dashboard_project_overview_path(@project), notice: "Project created!"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def settings
    end

    private

    def authenticate_via_sso!
      # In development, allow access
      return if Rails.env.development?

      unless session[:platform_user_id]
        platform_url = ENV.fetch("BRAINZLAB_PLATFORM_URL", "http://platform:3000")
        redirect_to "#{platform_url}/auth/sso?product=beacon&return_to=#{request.url}", allow_other_host: true
      end
    end

    def set_project
      @project = Project.find(params[:id])
    end

    def project_params
      params.require(:project).permit(:name, :timezone)
    end
  end
end
