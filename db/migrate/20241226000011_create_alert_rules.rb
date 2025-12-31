class CreateAlertRules < ActiveRecord::Migration[8.0]
  def change
    create_table :alert_rules, id: :uuid do |t|
      t.references :monitor, type: :uuid, null: false, foreign_key: true

      t.string :name, null: false
      t.boolean :enabled, default: true

      # Condition type and configuration
      t.string :condition_type, null: false  # status_change, response_time, ssl_expiry
      t.jsonb :condition_config, default: {}
      # Example condition_config:
      # {
      #   status_change: { from: "up", to: "down" },
      #   response_time: { operator: "gt", value: 1000 },
      #   ssl_expiry: { days_before: 30 }
      # }

      # Notification via Signal
      t.uuid :signal_alert_id

      t.timestamps

      t.index [ :monitor_id, :enabled ]
      t.index :condition_type
    end
  end
end
