class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_current_project

  rescue_from StandardError do |exception|
    BrainzLab::Reflex.capture(exception, context: { controller: self.class.name, action: action_name })
    BrainzLab::Signal.trigger("app.unhandled_error", severity: :critical, details: { error: exception.message })
    raise exception
  end

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
