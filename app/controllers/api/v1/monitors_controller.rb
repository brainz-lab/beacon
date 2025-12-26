module Api
  module V1
    class MonitorsController < BaseController
      before_action :set_monitor, only: [:show, :update, :destroy, :pause, :resume, :check_now, :uptime, :response_times]

      # GET /api/v1/monitors
      def index
        monitors = current_project.monitors

        monitors = monitors.by_status(params[:status]) if params[:status].present?
        monitors = monitors.where(monitor_type: params[:type]) if params[:type].present?
        monitors = monitors.where(enabled: params[:enabled] == "true") if params[:enabled].present?

        render json: {
          monitors: monitors.map { |m| monitor_json(m) },
          summary: current_project.monitors_summary
        }
      end

      # POST /api/v1/monitors
      def create
        monitor = current_project.monitors.create!(monitor_params)

        # Start monitoring
        ExecuteCheckJob.perform_later(monitor.id)

        render json: monitor_json(monitor, detailed: true), status: :created
      end

      # GET /api/v1/monitors/:id
      def show
        render json: monitor_json(@monitor, detailed: true)
      end

      # PATCH /api/v1/monitors/:id
      def update
        @monitor.update!(monitor_params)
        render json: monitor_json(@monitor, detailed: true)
      end

      # DELETE /api/v1/monitors/:id
      def destroy
        @monitor.destroy!
        head :no_content
      end

      # POST /api/v1/monitors/:id/pause
      def pause
        @monitor.update!(paused: true)
        render json: { paused: true, message: "Monitor paused" }
      end

      # POST /api/v1/monitors/:id/resume
      def resume
        @monitor.update!(paused: false)
        ExecuteCheckJob.perform_later(@monitor.id)
        render json: { paused: false, message: "Monitor resumed" }
      end

      # POST /api/v1/monitors/:id/check_now
      def check_now
        result = @monitor.check!
        render json: {
          success: result.success?,
          status: result.status,
          response_time_ms: result.response_time_ms,
          checked_at: result.checked_at
        }
      end

      # GET /api/v1/monitors/:id/uptime
      def uptime
        period = (params[:days] || 30).to_i.days
        calculator = UptimeCalculator.new(@monitor, period: period)

        render json: {
          uptime_percentage: calculator.calculate,
          downtime: calculator.downtime_humanized,
          uptime_bars: calculator.uptime_bars(days: period / 1.day)
        }
      end

      # GET /api/v1/monitors/:id/response_times
      def response_times
        period = (params[:hours] || 24).to_i.hours
        interval = params[:interval] || "1 hour"

        render json: {
          average: @monitor.average_response_time(period: period),
          series: @monitor.response_time_series(period: period, interval: interval)
        }
      end

      private

      def set_monitor
        @monitor = current_project.monitors.find(params[:id])
      end

      def monitor_params
        params.require(:monitor).permit(
          :name, :monitor_type, :url, :host, :port,
          :interval_seconds, :timeout_seconds,
          :http_method, :expected_status, :expected_body, :body,
          :follow_redirects, :verify_ssl,
          :auth_type, :confirmation_threshold, :recovery_threshold,
          :ssl_expiry_warn_days, :enabled, :paused,
          regions: [],
          headers: {},
          auth_config: {}
        )
      end

      def monitor_json(monitor, detailed: false)
        data = {
          id: monitor.id,
          name: monitor.name,
          type: monitor.monitor_type,
          url: monitor.url,
          host: monitor.host,
          port: monitor.port,
          status: monitor.status,
          enabled: monitor.enabled,
          paused: monitor.paused,
          last_check_at: monitor.last_check_at,
          last_up_at: monitor.last_up_at,
          last_down_at: monitor.last_down_at,
          created_at: monitor.created_at
        }

        if detailed
          data.merge!(
            interval_seconds: monitor.interval_seconds,
            timeout_seconds: monitor.timeout_seconds,
            regions: monitor.regions,
            http_method: monitor.http_method,
            expected_status: monitor.expected_status,
            expected_body: monitor.expected_body,
            follow_redirects: monitor.follow_redirects,
            verify_ssl: monitor.verify_ssl,
            auth_type: monitor.auth_type,
            confirmation_threshold: monitor.confirmation_threshold,
            recovery_threshold: monitor.recovery_threshold,
            ssl_expiry_at: monitor.ssl_expiry_at,
            ssl_expiry_warn_days: monitor.ssl_expiry_warn_days,
            consecutive_failures: monitor.consecutive_failures,
            consecutive_successes: monitor.consecutive_successes,
            uptime_30d: monitor.uptime(period: 30.days),
            avg_response_time: monitor.average_response_time,
            recent_checks: monitor.recent_checks(limit: 10).map { |c| check_json(c) },
            active_incident: monitor.active_incident&.then { |i| incident_json(i) }
          )
        end

        data
      end

      def check_json(check)
        {
          id: check.id,
          status: check.status,
          region: check.region,
          response_time_ms: check.response_time_ms,
          status_code: check.status_code,
          error_message: check.error_message,
          checked_at: check.checked_at
        }
      end

      def incident_json(incident)
        {
          id: incident.id,
          title: incident.title,
          status: incident.status,
          severity: incident.severity,
          started_at: incident.started_at,
          duration: incident.duration_humanized
        }
      end
    end
  end
end
