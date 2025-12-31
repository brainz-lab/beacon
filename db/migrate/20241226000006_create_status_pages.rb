class CreateStatusPages < ActiveRecord::Migration[8.0]
  def change
    create_table :status_pages, id: :uuid do |t|
      t.references :project, type: :uuid, null: false, foreign_key: true

      t.string :name, null: false
      t.string :slug, null: false
      t.string :custom_domain

      # Branding
      t.string :logo_url
      t.string :favicon_url
      t.string :primary_color, default: "#3B82F6"
      t.string :company_name
      t.string :company_url
      t.text :description

      # Settings
      t.boolean :public, default: true
      t.boolean :show_uptime, default: true
      t.boolean :show_response_time, default: true
      t.boolean :show_incidents, default: true
      t.integer :uptime_days_shown, default: 90

      # Subscription settings
      t.boolean :allow_subscriptions, default: true
      t.string :subscription_channels, array: true, default: [ "email" ]

      # Current status (cached)
      t.string :current_status, default: "operational"

      t.timestamps

      t.index :slug, unique: true
      t.index :custom_domain, unique: true
    end
  end
end
