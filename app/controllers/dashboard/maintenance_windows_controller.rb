module Dashboard
  class MaintenanceWindowsController < BaseController
    before_action :set_maintenance_window, only: [:show, :edit, :update, :destroy]

    def index
      @maintenance_windows = current_project.maintenance_windows.order(starts_at: :desc)

      case params[:status]
      when "upcoming"
        @maintenance_windows = @maintenance_windows.upcoming
      when "active"
        @maintenance_windows = @maintenance_windows.active
      when "past"
        @maintenance_windows = @maintenance_windows.past
      end
    end

    def show
      @affected_monitors = @maintenance_window.affected_monitors
    end

    def new
      @maintenance_window = current_project.maintenance_windows.build(
        starts_at: 1.day.from_now.beginning_of_hour,
        ends_at: 1.day.from_now.beginning_of_hour + 2.hours,
        timezone: "UTC",
        notify_subscribers: true,
        notify_before_minutes: 60
      )
      @available_monitors = current_project.monitors.enabled.order(:name)
    end

    def create
      @maintenance_window = current_project.maintenance_windows.build(maintenance_window_params)

      if @maintenance_window.save
        schedule_maintenance_jobs

        redirect_to dashboard_maintenance_window_path(@maintenance_window),
                    notice: "Maintenance window scheduled"
      else
        @available_monitors = current_project.monitors.enabled.order(:name)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @available_monitors = current_project.monitors.enabled.order(:name)
    end

    def update
      if @maintenance_window.update(maintenance_window_params)
        redirect_to dashboard_maintenance_window_path(@maintenance_window),
                    notice: "Maintenance window updated"
      else
        @available_monitors = current_project.monitors.enabled.order(:name)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @maintenance_window.cancel! if @maintenance_window.upcoming?
      @maintenance_window.destroy!

      redirect_to dashboard_maintenance_windows_path,
                  notice: "Maintenance window deleted"
    end

    private

    def set_maintenance_window
      @maintenance_window = current_project.maintenance_windows.find(params[:id])
    end

    def maintenance_window_params
      params.require(:maintenance_window).permit(
        :title, :description,
        :starts_at, :ends_at, :timezone,
        :affects_all_monitors,
        :notify_subscribers, :notify_before_minutes,
        monitor_ids: []
      )
    end

    def schedule_maintenance_jobs
      window = @maintenance_window

      # Schedule notification
      if window.notify_subscribers && window.notify_before_minutes.positive?
        notify_at = window.starts_at - window.notify_before_minutes.minutes
        if notify_at > Time.current
          MaintenanceWindowJob.set(wait_until: notify_at).perform_later("notify_upcoming", window.id)
        end
      end

      # Schedule start job
      if window.starts_at > Time.current
        MaintenanceWindowJob.set(wait_until: window.starts_at).perform_later("start", window.id)
      end
    end
  end
end
