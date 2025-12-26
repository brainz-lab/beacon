class CreateCheckResults < ActiveRecord::Migration[8.0]
  def change
    # Create table for TimescaleDB hypertable
    execute <<-SQL
      CREATE TABLE check_results (
        id uuid DEFAULT gen_random_uuid() NOT NULL,
        monitor_id uuid NOT NULL,
        checked_at timestamptz NOT NULL,
        region text NOT NULL,

        -- Result
        status text NOT NULL,
        response_time_ms integer,
        dns_time_ms integer,
        connect_time_ms integer,
        tls_time_ms integer,
        ttfb_ms integer,

        -- Response details
        status_code integer,
        response_size_bytes integer,
        error_message text,
        error_type text,

        -- SSL info (if checked)
        ssl_issuer text,
        ssl_expires_at timestamptz,
        ssl_valid boolean,

        -- DNS info (if checked)
        resolved_ip text,
        resolved_ips text[]
      );
    SQL

    # Convert to hypertable
    execute "SELECT create_hypertable('check_results', 'checked_at', if_not_exists => true);"

    # Indexes
    execute "CREATE INDEX idx_check_results_monitor_time ON check_results (monitor_id, checked_at DESC);"
    execute "CREATE INDEX idx_check_results_monitor_region_time ON check_results (monitor_id, region, checked_at DESC);"
    execute "CREATE INDEX idx_check_results_status ON check_results (status);"

    # Add foreign key constraint
    execute "ALTER TABLE check_results ADD CONSTRAINT fk_check_results_monitor FOREIGN KEY (monitor_id) REFERENCES monitors(id) ON DELETE CASCADE;"

    # Compression policy (compress data older than 7 days)
    # execute "SELECT add_compression_policy('check_results', INTERVAL '7 days', if_not_exists => true);"

    # Retention policy (delete data older than 90 days)
    # execute "SELECT add_retention_policy('check_results', INTERVAL '90 days', if_not_exists => true);"
  end
end
