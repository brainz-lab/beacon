module API
  module V1
    class BaseController < ActionController::API
      before_action :authenticate!

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :bad_request
      rescue_from ActionDispatch::Http::Parameters::ParseError, with: :handle_parse_error

      protected

      def authenticate!
        @current_project = authenticate_by_api_key || authenticate_by_bearer_token

        unless @current_project
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      end

      def current_project
        @current_project
      end

      private

      def authenticate_by_api_key
        api_key = request.headers["X-API-Key"]
        return nil unless api_key

        Project.find_by_api_key(api_key)
      end

      def authenticate_by_bearer_token
        auth_header = request.headers["Authorization"]
        return nil unless auth_header&.start_with?("Bearer ")

        token = auth_header.split(" ").last
        Project.find_by_api_key(token)
      end

      def not_found(exception)
        model = exception.model || "Record"
        id = exception.id
        message = id ? "#{model} not found with id=#{id}" : "#{model} not found"
        render json: { error: message }, status: :not_found
      end

      def unprocessable_entity(exception)
        render json: {
          error: "Validation failed",
          details: exception.record.errors.full_messages
        }, status: :unprocessable_entity
      end

      def bad_request(exception)
        response = { error: exception.message }
        if exception.param == "monitor"
          response[:hint] = "Wrap params in a 'monitor' key, e.g. {\"monitor\": {\"name\": \"...\", \"monitor_type\": \"http\", \"url\": \"...\"}}"
          response[:required_fields] = %w[name monitor_type url]
        elsif exception.param == "status_page"
          response[:hint] = "Wrap params in a 'status_page' key, e.g. {\"status_page\": {\"name\": \"...\", \"slug\": \"...\"}}"
          response[:required_fields] = %w[name slug]
        end
        render json: response, status: :bad_request
      end

      def handle_parse_error(exception)
        render json: { error: "Invalid JSON: #{exception.message}" }, status: :bad_request
      end

      def track_usage!(count = 1)
        return unless @current_project&.platform_project_id

        PlatformClient.track_usage(
          project_id: @current_project.platform_project_id,
          product: "beacon",
          metric: "checks",
          count: count
        )
      end

      def render_success(data, status: :ok)
        render json: data, status: status
      end

      def render_error(message, status: :unprocessable_entity)
        render json: { error: message }, status: status
      end
    end
  end
end
