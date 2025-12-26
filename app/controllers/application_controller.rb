class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_current_project

  private

  def set_current_project
    @current_project = nil
  end

  def current_project
    @current_project
  end
  helper_method :current_project

  def require_project!
    unless current_project
      respond_to do |format|
        format.html { redirect_to dashboard_setup_path }
        format.json { render json: { error: "Project not configured" }, status: :unprocessable_entity }
      end
    end
  end
end
