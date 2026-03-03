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
        permitted = params.require(:alert_rule).permit(
          :name, :condition_type, :enabled,
          :threshold, :comparison, :duration_minutes,
          notify_channels: []
        )

        # Map flat params into condition_config jsonb column
        config = {}
        config["threshold"] = permitted.delete(:threshold) if permitted.key?(:threshold)
        config["comparison"] = permitted.delete(:comparison) if permitted.key?(:comparison)
        config["duration_minutes"] = permitted.delete(:duration_minutes) if permitted.key?(:duration_minutes)
        config["notify_channels"] = permitted.delete(:notify_channels) if permitted.key?(:notify_channels)

        permitted[:condition_config] = config if config.present?
        permitted.except(:threshold, :comparison, :duration_minutes, :notify_channels)
      end

      def rule_json(rule, detailed: false)
        config = rule.condition_config || {}

        data = {
          id: rule.id,
          name: rule.name,
          condition_type: rule.condition_type,
          threshold: config["threshold"],
          comparison: config["comparison"],
          duration_minutes: config["duration_minutes"],
          enabled: rule.enabled,
          last_triggered_at: config["last_triggered_at"]
        }

        if detailed
          data.merge!(
            notify_channels: config["notify_channels"],
            condition_config: config,
            created_at: rule.created_at,
            updated_at: rule.updated_at
          )
        end

        data
      end
    end
  end
end
