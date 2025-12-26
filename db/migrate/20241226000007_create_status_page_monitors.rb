class CreateStatusPageMonitors < ActiveRecord::Migration[8.0]
  def change
    create_table :status_page_monitors, id: :uuid do |t|
      t.references :status_page, type: :uuid, null: false, foreign_key: true
      t.references :monitor, type: :uuid, null: false, foreign_key: true

      t.string :display_name            # Override monitor name
      t.string :group_name              # "API", "Website", "Services"
      t.integer :position, default: 0
      t.boolean :visible, default: true

      t.timestamps

      t.index [:status_page_id, :position]
      t.index [:status_page_id, :group_name]
      t.index [:status_page_id, :monitor_id], unique: true
    end
  end
end
