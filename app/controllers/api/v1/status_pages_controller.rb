module Api
  module V1
    class StatusPagesController < BaseController
      before_action :set_status_page, only: [:show, :update, :destroy]

      # GET /api/v1/status_pages
      def index
        status_pages = current_project.status_pages

        render json: {
          status_pages: status_pages.map { |sp| status_page_json(sp) }
        }
      end

      # POST /api/v1/status_pages
      def create
        status_page = current_project.status_pages.create!(status_page_params)

        render json: status_page_json(status_page, detailed: true), status: :created
      end

      # GET /api/v1/status_pages/:id
      def show
        render json: status_page_json(@status_page, detailed: true)
      end

      # PATCH /api/v1/status_pages/:id
      def update
        @status_page.update!(status_page_params)
        render json: status_page_json(@status_page, detailed: true)
      end

      # DELETE /api/v1/status_pages/:id
      def destroy
        @status_page.destroy!
        head :no_content
      end

      private

      def set_status_page
        @status_page = current_project.status_pages.find(params[:id])
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

      def status_page_json(status_page, detailed: false)
        data = {
          id: status_page.id,
          name: status_page.name,
          slug: status_page.slug,
          custom_domain: status_page.custom_domain,
          current_status: status_page.current_status,
          public: status_page.public,
          url: "/status/#{status_page.slug}",
          created_at: status_page.created_at
        }

        if detailed
          calculator = StatusCalculator.new(status_page)

          data.merge!(
            logo_url: status_page.logo_url,
            favicon_url: status_page.favicon_url,
            primary_color: status_page.primary_color,
            company_name: status_page.company_name,
            company_url: status_page.company_url,
            description: status_page.description,
            show_uptime: status_page.show_uptime,
            show_response_time: status_page.show_response_time,
            show_incidents: status_page.show_incidents,
            uptime_days_shown: status_page.uptime_days_shown,
            allow_subscriptions: status_page.allow_subscriptions,
            subscription_channels: status_page.subscription_channels,
            status_info: calculator.status_info,
            overall_uptime: status_page.overall_uptime,
            monitors_count: status_page.uptime_monitors.count,
            subscribers_count: status_page.confirmed_subscriptions.count,
            active_incidents_count: status_page.active_incidents.count
          )
        end

        data
      end
    end
  end
end
