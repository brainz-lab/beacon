class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects, id: :uuid do |t|
      # Links to Platform project
      t.uuid :platform_project_id, null: false

      # API authentication
      t.string :api_key, null: false
      t.string :ingest_key

      # Settings
      t.string :name
      t.jsonb :settings, default: {}

      t.timestamps

      t.index :platform_project_id, unique: true
      t.index :api_key, unique: true
      t.index :ingest_key, unique: true
    end
  end
end
