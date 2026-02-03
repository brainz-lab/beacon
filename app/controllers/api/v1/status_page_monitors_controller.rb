module Api
  module V1
    class StatusPageMonitorsController < Api::V1::BaseController
      before_action :set_status_page

      # GET /api/v1/status_pages/:status_page_id/monitors
      def index
        monitors = @status_page.status_page_monitors
                              .includes(:monitor)
                              .order(:display_order, :group_name)

        render json: {
          monitors: monitors.map { |spm| monitor_json(spm) },
          groups: @status_page.groups_with_monitors
        }
      end

      # POST /api/v1/status_pages/:status_page_id/monitors
      def create
        spm = @status_page.status_page_monitors.create!(spm_params)

        render json: monitor_json(spm), status: :created
      end

      # PATCH /api/v1/status_pages/:status_page_id/monitors/:id
      def update
        spm = @status_page.status_page_monitors.find(params[:id])
        spm.update!(spm_params)

        render json: monitor_json(spm)
      end

      # DELETE /api/v1/status_pages/:status_page_id/monitors/:id
      def destroy
        spm = @status_page.status_page_monitors.find(params[:id])
        spm.destroy!

        head :no_content
      end

      # POST /api/v1/status_pages/:status_page_id/monitors/reorder
      def reorder
        params[:order].each_with_index do |id, index|
          @status_page.status_page_monitors.find(id).update!(display_order: index)
        end

        render json: { success: true }
      end

      private

      def set_status_page
        @status_page = current_project.status_pages.find(params[:status_page_id])
      end

      def spm_params
        params.require(:status_page_monitor).permit(
          :monitor_id, :group_name, :display_name, :display_order
        )
      end

      def monitor_json(spm)
        {
          id: spm.id,
          monitor_id: spm.monitor_id,
          monitor_name: spm.monitor.name,
          display_name: spm.display_name,
          group_name: spm.group_name,
          display_order: spm.display_order,
          current_status: spm.monitor.status
        }
      end
    end
  end
end
