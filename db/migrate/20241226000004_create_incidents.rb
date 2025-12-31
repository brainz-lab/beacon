class CreateIncidents < ActiveRecord::Migration[8.0]
  def change
    create_table :incidents, id: :uuid do |t|
      t.references :monitor, type: :uuid, null: false, foreign_key: true

      t.string :title, null: false
      t.string :status, null: false          # investigating, identified, monitoring, resolved
      t.string :severity, default: "major"   # minor, major, critical

      # Timeline
      t.datetime :started_at, null: false
      t.datetime :identified_at
      t.datetime :resolved_at
      t.integer :duration_seconds

      # Impact
      t.string :affected_regions, array: true, default: []
      t.float :uptime_impact

      # Root cause
      t.text :root_cause
      t.text :resolution_notes

      # Notifications
      t.boolean :notified, default: false
      t.datetime :notified_at

      t.timestamps

      t.index [ :monitor_id, :started_at ]
      t.index [ :monitor_id, :status ]
      t.index :status
      t.index :started_at
    end
  end
end
