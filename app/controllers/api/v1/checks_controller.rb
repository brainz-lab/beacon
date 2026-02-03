module API
  module V1
    class ChecksController < API::V1::BaseController
      before_action :set_monitor

      # GET /api/v1/monitors/:monitor_id/checks
      def index
        checks = @monitor.check_results.recent

        # Filter by region
        checks = checks.in_region(params[:region]) if params[:region].present?

        # Filter by status
        checks = checks.where(status: params[:status]) if params[:status].present?

        # Filter by date range
        if params[:since].present?
          checks = checks.where("checked_at >= ?", Time.parse(params[:since]))
        end
        if params[:until].present?
          checks = checks.where("checked_at <= ?", Time.parse(params[:until]))
        end

        # Pagination
        limit = [ params.fetch(:limit, 100).to_i, 1000 ].min
        offset = params.fetch(:offset, 0).to_i

        total = checks.count
        checks = checks.limit(limit).offset(offset)

        render json: {
          checks: checks.map { |c| check_json(c) },
          pagination: {
            total: total,
            limit: limit,
            offset: offset
          }
        }
      end

      private

      def set_monitor
        @monitor = current_project.uptime_monitors.find(params[:monitor_id])
      end

      def check_json(check)
        {
          id: check.id,
          status: check.status,
          region: check.region,
          response_time_ms: check.response_time_ms,
          dns_time_ms: check.dns_time_ms,
          connect_time_ms: check.connect_time_ms,
          tls_time_ms: check.tls_time_ms,
          ttfb_ms: check.ttfb_ms,
          status_code: check.status_code,
          response_size_bytes: check.response_size_bytes,
          error_message: check.error_message,
          error_type: check.error_type,
          ssl_valid: check.ssl_valid,
          ssl_expires_at: check.ssl_expires_at,
          resolved_ip: check.resolved_ip,
          checked_at: check.checked_at
        }
      end
    end
  end
end
