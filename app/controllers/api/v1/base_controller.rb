module API
  module V1
    class BaseController < ActionController::API
      before_action :authenticate!

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :bad_request

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
        render json: { error: exception.message }, status: :not_found
      end

      def unprocessable_entity(exception)
        render json: {
          error: "Validation failed",
          details: exception.record.errors.full_messages
        }, status: :unprocessable_entity
      end

      def bad_request(exception)
        render json: { error: exception.message }, status: :bad_request
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
