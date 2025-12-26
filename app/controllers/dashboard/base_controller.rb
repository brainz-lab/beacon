module Dashboard
  class BaseController < ApplicationController
    layout "dashboard"

    before_action :authenticate_user!
    before_action :set_current_project

    helper_method :current_project

    private

    def authenticate_user!
      # For now, use session-based auth
      # In production, integrate with Platform SSO
      unless session[:user_id].present? || Rails.env.development?
        redirect_to dashboard_setup_path and return
      end
    end

    def set_current_project
      @current_project = if session[:project_id].present?
        Project.find_by(id: session[:project_id])
      else
        Project.first # Development fallback
      end

      unless @current_project
        redirect_to dashboard_setup_path and return
      end
    end

    def current_project
      @current_project
    end

    def set_breadcrumbs
      @breadcrumbs = []
    end

    def add_breadcrumb(title, path = nil)
      @breadcrumbs ||= []
      @breadcrumbs << { title: title, path: path }
    end
  end
end
