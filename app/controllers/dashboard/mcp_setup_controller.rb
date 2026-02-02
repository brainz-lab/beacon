module Dashboard
  class MCPSetupController < BaseController
    before_action :require_project!

    def index
      @api_key = @project.api_key
    end
  end
end
