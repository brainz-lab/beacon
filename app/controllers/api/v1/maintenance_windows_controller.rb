module Api
  module V1
    class MaintenanceWindowsController < BaseController
      before_action :set_maintenance_window, only: [ :show, :update, :destroy ]

      # GET /api/v1/maintenance_windows
      def index
        windows = current_project.maintenance_windows

        case params[:status]
        when "upcoming"
          windows = windows.upcoming
        when "active"
          windows = windows.active
        when "past"
          windows = windows.past
        end

        windows = windows.order(:starts_at).limit(params.fetch(:limit, 50).to_i)

        render json: {
          maintenance_windows: windows.map { |w| window_json(w) }
        }
      end

      # POST /api/v1/maintenance_windows
      def create
        window = current_project.maintenance_windows.create!(window_params)

        # Schedule notification if configured
        if window.notify_subscribers && window.notify_before_minutes.positive?
          notify_at = window.starts_at - window.notify_before_minutes.minutes
          if notify_at > Time.current
            MaintenanceWindowJob.set(wait_until: notify_at).perform_later("notify_upcoming", window.id)
          end
        end

        # Schedule start/end jobs
        if window.starts_at > Time.current
          MaintenanceWindowJob.set(wait_until: window.starts_at).perform_later("start", window.id)
        end

        render json: window_json(window, detailed: true), status: :created
      end

      # GET /api/v1/maintenance_windows/:id
      def show
        render json: window_json(@maintenance_window, detailed: true)
      end

      # PATCH /api/v1/maintenance_windows/:id
      def update
        @maintenance_window.update!(window_params)
        render json: window_json(@maintenance_window, detailed: true)
      end

      # DELETE /api/v1/maintenance_windows/:id
      def destroy
        @maintenance_window.cancel! if @maintenance_window.upcoming?
        @maintenance_window.destroy!
        head :no_content
      end

      private

      def set_maintenance_window
        @maintenance_window = current_project.maintenance_windows.find(params[:id])
      end

      def window_params
        params.require(:maintenance_window).permit(
          :title, :description,
          :starts_at, :ends_at, :timezone,
          :affects_all_monitors,
          :notify_subscribers, :notify_before_minutes,
          monitor_ids: []
        )
      end

      def window_json(window, detailed: false)
        data = {
          id: window.id,
          title: window.title,
          status: window.status,
          starts_at: window.starts_at,
          ends_at: window.ends_at,
          duration: window.duration_humanized,
          created_at: window.created_at
        }

        if detailed
          data.merge!(
            description: window.description,
            timezone: window.timezone,
            affects_all_monitors: window.affects_all_monitors,
            monitor_ids: window.monitor_ids,
            affected_monitors: window.affected_monitors.map { |m| { id: m.id, name: m.name } },
            notify_subscribers: window.notify_subscribers,
            notify_before_minutes: window.notify_before_minutes,
            notified: window.notified
          )
        end

        data
      end
    end
  end
end
