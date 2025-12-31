module Dashboard
  class StatusPagesController < BaseController
    before_action :require_project!
    before_action :set_status_page, only: [ :show, :edit, :update, :destroy ]

    def index
      @status_pages = @project.status_pages.order(:name)
    end

    def show
      @calculator = StatusCalculator.new(@status_page)
      @monitors_by_group = @status_page.monitors_by_group
      @active_incidents = @status_page.active_incidents
      @subscriber_count = @status_page.confirmed_subscriptions.count
    end

    def new
      @status_page = @project.status_pages.build(
        public: true,
        show_uptime: true,
        show_response_time: true,
        show_incidents: true,
        uptime_days_shown: 90,
        allow_subscriptions: true,
        subscription_channels: [ "email" ]
      )
    end

    def create
      @status_page = @project.status_pages.build(status_page_params)

      if @status_page.save
        redirect_to dashboard_project_status_page_path(@project, @status_page),
                    notice: "Status page created"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @available_monitors = @project.uptime_monitors.order(:name)
    end

    def update
      if @status_page.update(status_page_params)
        redirect_to dashboard_project_status_page_path(@project, @status_page),
                    notice: "Status page updated"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @status_page.destroy!
      redirect_to dashboard_project_status_pages_path(@project),
                  notice: "Status page deleted"
    end

    private

    def set_status_page
      @status_page = @project.status_pages.find(params[:id])
    end

    def status_page_params
      params.require(:status_page).permit(
        :name, :slug, :custom_domain,
        :logo_url, :favicon_url, :primary_color,
        :company_name, :company_url, :description,
        :public, :show_uptime, :show_response_time, :show_incidents,
        :uptime_days_shown, :allow_subscriptions,
        subscription_channels: []
      )
    end
  end
end
