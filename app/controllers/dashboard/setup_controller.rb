module Dashboard
  class SetupController < BaseController
    before_action :require_project!

    def index
      @api_key = @project.api_key
      @ingest_key = @project.ingest_key
    end
  end
end
