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

      # Handles ParameterMissing errors when required wrapper keys are absent.
      # Note: Rails wrap_parameters automatically wraps flat JSON params under
      # the resource key (e.g. {"name": "x"} becomes {monitor: {name: "x"}}),
      # so both wrapped and flat params work. This error only triggers with
      # truly empty bodies or bodies missing required fields entirely.
      def bad_request(exception)
        response = { error: exception.message }
        if exception.param == "monitor"
          response[:hint] = "Send monitor params as JSON, e.g. {\"name\": \"...\", \"monitor_type\": \"http\", \"url\": \"...\"}. Wrapping under a 'monitor' key is optional."
          response[:required_fields] = %w[name monitor_type url]
        elsif exception.param == "status_page"
          response[:hint] = "Send status page params as JSON, e.g. {\"name\": \"...\", \"slug\": \"...\"}. Wrapping under a 'status_page' key is optional."
          response[:required_fields] = %w[name slug]
        end
        render json: response, status: :bad_request
      end

      def handle_parse_error(exception)
        render json: { error: "Invalid JSON: #{exception.message}" }, status: :bad_request
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
