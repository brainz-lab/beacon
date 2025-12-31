class CreateMonitors < ActiveRecord::Migration[8.0]
  def change
    create_table :monitors, id: :uuid do |t|
      t.references :project, type: :uuid, null: false, foreign_key: true

      # Basic info
      t.string :name, null: false
      t.string :monitor_type, null: false  # http, tcp, dns, ssl, ping
      t.boolean :enabled, default: true
      t.boolean :paused, default: false

      # Target
      t.string :url                         # For HTTP checks
      t.string :host                        # For TCP/DNS/Ping
      t.integer :port                       # For TCP

      # Check configuration
      t.integer :interval_seconds, default: 60
      t.integer :timeout_seconds, default: 30
      t.string :regions, array: true, default: [ "nyc" ]

      # HTTP-specific
      t.string :http_method, default: "GET"
      t.jsonb :headers, default: {}
      t.text :body
      t.integer :expected_status, default: 200
      t.string :expected_body
      t.boolean :follow_redirects, default: true
      t.boolean :verify_ssl, default: true

      # Authentication
      t.string :auth_type                   # basic, bearer, header
      t.jsonb :auth_config, default: {}     # Encrypted credentials

      # Alerting thresholds
      t.integer :confirmation_threshold, default: 2
      t.integer :recovery_threshold, default: 2

      # Current state
      t.string :status, default: "unknown"  # up, down, degraded, unknown
      t.datetime :last_check_at
      t.datetime :last_up_at
      t.datetime :last_down_at
      t.integer :consecutive_failures, default: 0
      t.integer :consecutive_successes, default: 0

      # SSL monitoring
      t.datetime :ssl_expiry_at
      t.integer :ssl_expiry_warn_days, default: 30

      t.timestamps

      t.index [ :project_id, :enabled ]
      t.index :status
      t.index [ :project_id, :status ]
    end
  end
end
