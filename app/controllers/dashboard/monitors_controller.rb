module Dashboard
  class MonitorsController < BaseController
    before_action :require_project!
    before_action :set_monitor, only: [ :show, :edit, :update, :destroy, :pause, :resume, :check_now ]

    def index
      @monitors = @project.uptime_monitors.includes(:check_results).order(:name)

      case params[:status]
      when "healthy" then @monitors = @monitors.healthy
      when "degraded" then @monitors = @monitors.degraded
      when "down" then @monitors = @monitors.down
      when "paused" then @monitors = @monitors.paused
      end

      @monitors = @monitors.where(check_type: params[:type]) if params[:type].present?
    end

    def show
      @recent_checks = @monitor.check_results
                               .order(checked_at: :desc)
                               .limit(100)

      @uptime_calculator = UptimeCalculator.new(@monitor)
      @incidents = @monitor.incidents.recent.limit(10)

      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    def new
      @monitor = @project.uptime_monitors.build(
        check_type: "http",
        interval: 60,
        timeout: 30000,
        regions: [ "nyc" ],
        enabled: true
      )
    end

    def create
      @monitor = @project.uptime_monitors.build(monitor_params)

      if @monitor.save
        # Schedule first check
        ExecuteCheckJob.perform_later(@monitor.id)

        redirect_to dashboard_project_monitor_path(@project, @monitor),
                    notice: "Monitor created successfully"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @monitor.update(monitor_params)
        redirect_to dashboard_project_monitor_path(@project, @monitor),
                    notice: "Monitor updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @monitor.destroy!
      redirect_to dashboard_project_monitors_path(@project),
                  notice: "Monitor deleted"
    end

    def pause
      @monitor.pause!
      respond_to do |format|
        format.html { redirect_to dashboard_project_monitor_path(@project, @monitor), notice: "Monitor paused" }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@monitor) }
      end
    end

    def resume
      @monitor.resume!
      ExecuteCheckJob.perform_later(@monitor.id)

      respond_to do |format|
        format.html { redirect_to dashboard_project_monitor_path(@project, @monitor), notice: "Monitor resumed" }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@monitor) }
      end
    end

    def check_now
      ExecuteCheckJob.perform_later(@monitor.id)

      respond_to do |format|
        format.html { redirect_to dashboard_project_monitor_path(@project, @monitor), notice: "Check queued" }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@monitor) }
      end
    end

    private

    def set_monitor
      @monitor = @project.uptime_monitors.find(params[:id])
    end

    def monitor_params
      params.require(:monitor).permit(
        :name, :url, :host, :port, :check_type,
        :interval, :timeout, :enabled,
        :http_method, :expected_status, :expected_body,
        :follow_redirects, :verify_ssl,
        :dns_record_type, :expected_dns_result,
        :auth_type, :auth_username, :auth_password,
        :failure_threshold, :success_threshold,
        regions: [],
        headers: {}
      )
    end
  end
end
