module API
  module V1
    class AlertRulesController < API::V1::BaseController
      before_action :set_monitor
      before_action :set_alert_rule, only: [ :show, :update, :destroy ]

      # GET /api/v1/monitors/:monitor_id/alert_rules
      def index
        rules = @monitor.alert_rules.order(:created_at)

        render json: {
          alert_rules: rules.map { |r| rule_json(r) }
        }
      end

      # POST /api/v1/monitors/:monitor_id/alert_rules
      def create
        rule = @monitor.alert_rules.create!(rule_params)

        render json: rule_json(rule), status: :created
      end

      # GET /api/v1/monitors/:monitor_id/alert_rules/:id
      def show
        render json: rule_json(@alert_rule, detailed: true)
      end

      # PATCH /api/v1/monitors/:monitor_id/alert_rules/:id
      def update
        @alert_rule.update!(rule_params)
        render json: rule_json(@alert_rule, detailed: true)
      end

      # DELETE /api/v1/monitors/:monitor_id/alert_rules/:id
      def destroy
        @alert_rule.destroy!
        head :no_content
      end

      private

      def set_monitor
        @monitor = current_project.uptime_monitors.find(params[:monitor_id])
      end

      def set_alert_rule
        @alert_rule = @monitor.alert_rules.find(params[:id])
      end

      def rule_params
        params.require(:alert_rule).permit(
          :name, :condition_type, :threshold, :comparison,
          :duration_minutes, :enabled,
          notify_channels: []
        )
      end

      def rule_json(rule, detailed: false)
        data = {
          id: rule.id,
          name: rule.name,
          condition_type: rule.condition_type,
          threshold: rule.threshold,
          comparison: rule.comparison,
          duration_minutes: rule.duration_minutes,
          enabled: rule.enabled,
          last_triggered_at: rule.last_triggered_at
        }

        if detailed
          data.merge!(
            notify_channels: rule.notify_channels,
            created_at: rule.created_at,
            updated_at: rule.updated_at
          )
        end

        data
      end
    end
  end
end
