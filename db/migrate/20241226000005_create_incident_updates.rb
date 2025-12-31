class CreateIncidentUpdates < ActiveRecord::Migration[8.0]
  def change
    create_table :incident_updates, id: :uuid do |t|
      t.references :incident, type: :uuid, null: false, foreign_key: true

      t.string :status, null: false          # investigating, identified, monitoring, resolved
      t.text :message, null: false
      t.string :created_by                   # User email or 'system'

      t.datetime :created_at, null: false

      t.index [ :incident_id, :created_at ]
    end
  end
end
