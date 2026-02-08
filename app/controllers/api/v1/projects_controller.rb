# frozen_string_literal: true

module API
  module V1
    class ProjectsController < ActionController::API
      before_action :authenticate_master_key!, only: [:provision]

      # POST /api/v1/projects/provision
      # Creates a new project or returns existing one, linked to Platform
      def provision
        platform_project_id = params[:platform_project_id]
        name = params[:name].to_s.strip

        if platform_project_id.present?
          project = Project.find_or_initialize_by(platform_project_id: platform_project_id)
          project.name = name if name.present?
          project.save!
        elsif name.present?
          project = Project.find_or_initialize_by(name: name)
          project.platform_project_id ||= SecureRandom.uuid
          project.save!
        else
          return render json: { error: "Either platform_project_id or name is required" }, status: :bad_request
        end

        render json: {
          id: project.id,
          platform_project_id: project.platform_project_id,
          name: project.name,
          api_key: project.api_key,
          ingest_key: project.ingest_key
        }, status: project.previously_new_record? ? :created : :ok
      end

      # GET /api/v1/projects/lookup
      # Looks up a project by name or platform_project_id
      def lookup
        project = find_project

        if project
          render json: {
            id: project.id,
            platform_project_id: project.platform_project_id,
            name: project.name,
            api_key: project.api_key,
            ingest_key: project.ingest_key
          }
        else
          render json: { error: "Project not found" }, status: :not_found
        end
      end

      private

      def find_project
        if params[:platform_project_id].present?
          Project.find_by(platform_project_id: params[:platform_project_id])
        elsif params[:name].present?
          Project.find_by(name: params[:name])
        end
      end

      def authenticate_master_key!
        key = request.headers["X-Master-Key"]
        expected = ENV["BEACON_MASTER_KEY"]

        return if key.present? && expected.present? && ActiveSupport::SecurityUtils.secure_compare(key, expected)

        render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end
  end
end
