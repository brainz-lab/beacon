# frozen_string_literal: true

# Client for communicating with BrainzLab Platform
# Handles usage tracking for billing
class PlatformClient
  PLATFORM_URL = ENV.fetch("BRAINZLAB_PLATFORM_URL", "https://platform.brainzlab.ai")
  TIMEOUT = 5

  class << self
    # Track usage metrics (for billing)
    def track_usage(project_id:, product:, metric:, count:)
      return if count <= 0

      Thread.new do
        uri = URI("#{PLATFORM_URL}/api/v1/usage/track")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = TIMEOUT
        http.read_timeout = TIMEOUT

        request = Net::HTTP::Post.new(uri.path)
        request["Content-Type"] = "application/json"
        request["X-Service-Key"] = Rails.application.credentials.dig(:service_key) || ENV["SERVICE_KEY"]
        request.body = {
          project_id: project_id,
          product: product,
          metric: metric,
          count: count
        }.to_json

        http.request(request)
      rescue StandardError => e
        Rails.logger.error("[PlatformClient] Usage tracking failed: #{e.message}")
      end
    end
  end
end
