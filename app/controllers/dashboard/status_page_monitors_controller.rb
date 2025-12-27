module Dashboard
  class StatusPageMonitorsController < BaseController
    before_action :require_project!
    before_action :set_status_page
    before_action :set_status_page_monitor, only: [:update, :destroy]

    def create
      @spm = @status_page.status_page_monitors.build(spm_params)

      if @spm.save
        respond_to do |format|
          format.html { redirect_to dashboard_project_status_page_path(@project, @status_page), notice: "Monitor added" }
          format.turbo_stream
        end
      else
        respond_to do |format|
          format.html { redirect_to dashboard_project_status_page_path(@project, @status_page), alert: @spm.errors.full_messages.join(", ") }
          format.turbo_stream { render turbo_stream: turbo_stream.replace("add_monitor_form", partial: "form", locals: { status_page: @status_page, spm: @spm }) }
        end
      end
    end

    def update
      if @spm.update(spm_params)
        respond_to do |format|
          format.html { redirect_to dashboard_project_status_page_path(@project, @status_page), notice: "Monitor updated" }
          format.turbo_stream { render turbo_stream: turbo_stream.replace(@spm) }
        end
      else
        respond_to do |format|
          format.html { redirect_to dashboard_project_status_page_path(@project, @status_page), alert: @spm.errors.full_messages.join(", ") }
          format.turbo_stream
        end
      end
    end

    def destroy
      @spm.destroy!

      respond_to do |format|
        format.html { redirect_to dashboard_project_status_page_path(@project, @status_page), notice: "Monitor removed" }
        format.turbo_stream { render turbo_stream: turbo_stream.remove(@spm) }
      end
    end

    private

    def set_status_page
      @status_page = @project.status_pages.find(params[:status_page_id])
    end

    def set_status_page_monitor
      @spm = @status_page.status_page_monitors.find(params[:id])
    end

    def spm_params
      params.require(:status_page_monitor).permit(
        :monitor_id, :display_name, :group_name, :display_order
      )
    end
  end
end
