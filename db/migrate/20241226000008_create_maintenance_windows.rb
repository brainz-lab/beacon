class CreateMaintenanceWindows < ActiveRecord::Migration[8.0]
  def change
    create_table :maintenance_windows, id: :uuid do |t|
      t.references :project, type: :uuid, null: false, foreign_key: true

      t.string :title, null: false
      t.text :description

      # Timing
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :timezone, default: "UTC"

      # Affected monitors
      t.uuid :monitor_ids, array: true, default: []
      t.boolean :affects_all_monitors, default: false

      # Status
      t.string :status, default: "scheduled"  # scheduled, in_progress, completed, cancelled

      # Notifications
      t.boolean :notify_subscribers, default: true
      t.integer :notify_before_minutes, default: 60
      t.boolean :notified, default: false

      t.timestamps

      t.index [:project_id, :starts_at]
      t.index :status
      t.index :starts_at
    end
  end
end
