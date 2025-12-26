# Beacon - Uptime Monitoring

## Overview

Beacon is an uptime monitoring service that watches your endpoints, APIs, and services. Get instant alerts when things go down.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│                               BEACON                                         │
│                         "Always watching"                                    │
│                                                                              │
│   ┌──────────────────────────────────────────────────────────────────────┐   │
│   │                                                                      │   │
│   │     🌎 Global Monitoring Network                                     │   │
│   │                                                                      │   │
│   │     ┌─────┐         ┌─────┐         ┌─────┐         ┌─────┐        │   │
│   │     │ NYC │         │ LON │         │ SIN │         │ SYD │        │   │
│   │     └──┬──┘         └──┬──┘         └──┬──┘         └──┬──┘        │   │
│   │        │               │               │               │            │   │
│   │        └───────────────┴───────┬───────┴───────────────┘            │   │
│   │                                │                                     │   │
│   │                                ▼                                     │   │
│   │                    ┌───────────────────────┐                        │   │
│   │                    │    YOUR ENDPOINTS     │                        │   │
│   │                    │                       │                        │   │
│   │                    │  api.myapp.com    ✅  │                        │   │
│   │                    │  myapp.com        ✅  │                        │   │
│   │                    │  admin.myapp.com  ⚠️  │                        │   │
│   │                    │  db.myapp.com     ❌  │                        │   │
│   │                    │                       │                        │   │
│   │                    └───────────────────────┘                        │   │
│   │                                                                      │   │
│   └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│   │    HTTP     │  │     SSL     │  │    DNS      │  │   Status    │        │
│   │   Checks    │  │   Monitor   │  │   Monitor   │  │    Page     │        │
│   │             │  │             │  │             │  │             │        │
│   │ Status code │  │ Expiry warn │  │ Resolution  │  │ Public page │        │
│   │ Response    │  │ Cert valid  │  │ Propagation │  │ Incidents   │        │
│   └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                                              │
│   Features: Multi-region • SSL expiry • DNS checks • Status pages •         │
│             Incident management • Response time tracking • Webhooks         │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **API** | Rails 8 API | Monitor management |
| **Checker** | Ruby workers | Execute health checks |
| **Scheduler** | Solid Queue | Check scheduling |
| **Database** | PostgreSQL | Monitors, results |
| **Time-series** | TimescaleDB | Response time history |
| **Cache** | Redis | Status cache, rate limiting |
| **Real-time** | ActionCable | Live status updates |
| **Regions** | Fly.io/Railway | Multi-region checkers |

---

## Directory Structure

```
beacon/
├── README.md
├── Dockerfile
├── docker-compose.yml
├── .env.example
│
├── config/
│   ├── routes.rb
│   ├── database.yml
│   └── initializers/
│       ├── regions.rb
│       └── checker.rb
│
├── app/
│   ├── controllers/
│   │   ├── api/v1/
│   │   │   ├── monitors_controller.rb
│   │   │   ├── checks_controller.rb
│   │   │   ├── incidents_controller.rb
│   │   │   ├── status_pages_controller.rb
│   │   │   └── maintenance_controller.rb
│   │   └── public/
│   │       └── status_controller.rb
│   │
│   ├── models/
│   │   ├── monitor.rb
│   │   ├── check_result.rb
│   │   ├── incident.rb
│   │   ├── incident_update.rb
│   │   ├── status_page.rb
│   │   ├── status_page_monitor.rb
│   │   ├── maintenance_window.rb
│   │   ├── ssl_certificate.rb
│   │   └── alert_rule.rb
│   │
│   ├── services/
│   │   ├── checkers/
│   │   │   ├── base_checker.rb
│   │   │   ├── http_checker.rb
│   │   │   ├── tcp_checker.rb
│   │   │   ├── dns_checker.rb
│   │   │   ├── ssl_checker.rb
│   │   │   └── ping_checker.rb
│   │   ├── incident_manager.rb
│   │   ├── status_calculator.rb
│   │   ├── uptime_calculator.rb
│   │   └── response_time_analyzer.rb
│   │
│   ├── jobs/
│   │   ├── execute_check_job.rb
│   │   ├── schedule_checks_job.rb
│   │   ├── ssl_expiry_check_job.rb
│   │   ├── incident_notification_job.rb
│   │   └── cleanup_old_checks_job.rb
│   │
│   └── channels/
│       ├── monitor_channel.rb
│       └── status_page_channel.rb
│
├── lib/
│   └── beacon/
│       ├── mcp/
│       │   ├── server.rb
│       │   └── tools/
│       │       ├── list_monitors.rb
│       │       ├── check_status.rb
│       │       ├── create_monitor.rb
│       │       ├── get_uptime.rb
│       │       └── list_incidents.rb
│       └── regions/
│           ├── coordinator.rb
│           └── worker.rb
│
└── spec/
    ├── models/
    ├── services/
    └── requests/
```

---

## Database Schema

```ruby
# db/migrate/001_create_monitors.rb

class CreateMonitors < ActiveRecord::Migration[8.0]
  def change
    create_table :monitors, id: :uuid do |t|
      t.references :platform_project, type: :uuid, null: false
      
      # Basic info
      t.string :name, null: false
      t.string :monitor_type, null: false        # http, tcp, dns, ssl, ping
      t.boolean :enabled, default: true
      t.boolean :paused, default: false
      
      # Target
      t.string :url                               # For HTTP checks
      t.string :host                              # For TCP/DNS/Ping
      t.integer :port                             # For TCP
      
      # Check configuration
      t.integer :interval_seconds, default: 60   # Check frequency
      t.integer :timeout_seconds, default: 30    # Request timeout
      t.string :regions, array: true, default: ['nyc']  # Check from these regions
      
      # HTTP-specific
      t.string :http_method, default: 'GET'
      t.jsonb :headers, default: {}
      t.text :body
      t.integer :expected_status, default: 200
      t.string :expected_body                     # String to find in response
      t.boolean :follow_redirects, default: true
      t.boolean :verify_ssl, default: true
      
      # Authentication
      t.string :auth_type                         # basic, bearer, header
      t.jsonb :auth_config, default: {}          # Encrypted credentials
      
      # Alerting
      t.integer :confirmation_threshold, default: 2  # Checks before alerting
      t.integer :recovery_threshold, default: 2      # Checks before recovery
      
      # Current state
      t.string :status, default: 'unknown'       # up, down, degraded, unknown
      t.datetime :last_check_at
      t.datetime :last_up_at
      t.datetime :last_down_at
      t.integer :consecutive_failures, default: 0
      t.integer :consecutive_successes, default: 0
      
      # SSL monitoring
      t.datetime :ssl_expiry_at
      t.integer :ssl_expiry_warn_days, default: 30
      
      t.timestamps
      
      t.index :platform_project_id
      t.index [:platform_project_id, :enabled]
      t.index :status
    end
  end
end

# db/migrate/002_create_check_results.rb

class CreateCheckResults < ActiveRecord::Migration[8.0]
  def change
    # Using TimescaleDB hypertable for time-series data
    create_table :check_results, id: :uuid do |t|
      t.references :monitor, type: :uuid, null: false, foreign_key: true
      
      t.datetime :checked_at, null: false
      t.string :region, null: false              # nyc, lon, sin, syd
      
      # Result
      t.string :status, null: false              # up, down, degraded
      t.integer :response_time_ms                # Total response time
      t.integer :dns_time_ms                     # DNS lookup time
      t.integer :connect_time_ms                 # TCP connect time
      t.integer :tls_time_ms                     # TLS handshake time
      t.integer :ttfb_ms                         # Time to first byte
      
      # Response details
      t.integer :status_code
      t.integer :response_size_bytes
      t.text :error_message
      t.string :error_type                       # timeout, dns_error, ssl_error, connection_refused
      
      # SSL info (if checked)
      t.string :ssl_issuer
      t.datetime :ssl_expires_at
      t.boolean :ssl_valid
      
      # DNS info (if checked)
      t.string :resolved_ip
      t.string :resolved_ips, array: true
      
      t.index [:monitor_id, :checked_at]
      t.index [:monitor_id, :region, :checked_at]
    end
    
    # Convert to TimescaleDB hypertable
    execute "SELECT create_hypertable('check_results', 'checked_at')"
    
    # Add compression policy (compress data older than 7 days)
    execute "SELECT add_compression_policy('check_results', INTERVAL '7 days')"
    
    # Add retention policy (delete data older than 90 days)
    execute "SELECT add_retention_policy('check_results', INTERVAL '90 days')"
  end
end

# db/migrate/003_create_incidents.rb

class CreateIncidents < ActiveRecord::Migration[8.0]
  def change
    create_table :incidents, id: :uuid do |t|
      t.references :monitor, type: :uuid, null: false, foreign_key: true
      
      t.string :title, null: false
      t.string :status, null: false              # investigating, identified, monitoring, resolved
      t.string :severity, default: 'major'       # minor, major, critical
      
      # Timeline
      t.datetime :started_at, null: false
      t.datetime :identified_at
      t.datetime :resolved_at
      t.integer :duration_seconds
      
      # Impact
      t.string :affected_regions, array: true, default: []
      t.float :uptime_impact                     # Percentage points lost
      
      # Root cause
      t.text :root_cause
      t.text :resolution_notes
      
      # Notifications
      t.boolean :notified, default: false
      t.datetime :notified_at
      
      t.timestamps
      
      t.index [:monitor_id, :started_at]
      t.index [:monitor_id, :status]
    end
  end
end

# db/migrate/004_create_incident_updates.rb

class CreateIncidentUpdates < ActiveRecord::Migration[8.0]
  def change
    create_table :incident_updates, id: :uuid do |t|
      t.references :incident, type: :uuid, null: false, foreign_key: true
      
      t.string :status, null: false              # investigating, identified, monitoring, resolved
      t.text :message, null: false
      t.string :created_by                       # User email or 'system'
      
      t.datetime :created_at, null: false
      
      t.index [:incident_id, :created_at]
    end
  end
end

# db/migrate/005_create_status_pages.rb

class CreateStatusPages < ActiveRecord::Migration[8.0]
  def change
    create_table :status_pages, id: :uuid do |t|
      t.references :platform_project, type: :uuid, null: false
      
      t.string :name, null: false
      t.string :slug, null: false                # status.myapp.com or myapp.brainzlab.ai/status
      t.string :custom_domain                    # status.mycompany.com
      
      # Branding
      t.string :logo_url
      t.string :favicon_url
      t.string :primary_color, default: '#3B82F6'
      t.string :company_name
      t.string :company_url
      t.text :description
      
      # Settings
      t.boolean :public, default: true
      t.boolean :show_uptime, default: true
      t.boolean :show_response_time, default: true
      t.boolean :show_incidents, default: true
      t.integer :uptime_days_shown, default: 90
      
      # Subscription
      t.boolean :allow_subscriptions, default: true
      t.string :subscription_channels, array: true, default: ['email']
      
      # Current status (cached)
      t.string :current_status, default: 'operational'  # operational, degraded, partial_outage, major_outage
      
      t.timestamps
      
      t.index :slug, unique: true
      t.index :custom_domain, unique: true
    end
  end
end

# db/migrate/006_create_status_page_monitors.rb

class CreateStatusPageMonitors < ActiveRecord::Migration[8.0]
  def change
    create_table :status_page_monitors, id: :uuid do |t|
      t.references :status_page, type: :uuid, null: false, foreign_key: true
      t.references :monitor, type: :uuid, null: false, foreign_key: true
      
      t.string :display_name                     # Override monitor name
      t.string :group_name                       # "API", "Website", "Services"
      t.integer :position, default: 0
      t.boolean :visible, default: true
      
      t.timestamps
      
      t.index [:status_page_id, :position]
      t.index [:status_page_id, :group_name]
    end
  end
end

# db/migrate/007_create_maintenance_windows.rb

class CreateMaintenanceWindows < ActiveRecord::Migration[8.0]
  def change
    create_table :maintenance_windows, id: :uuid do |t|
      t.references :platform_project, type: :uuid, null: false
      
      t.string :title, null: false
      t.text :description
      
      # Timing
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :timezone, default: 'UTC'
      
      # Affected monitors
      t.uuid :monitor_ids, array: true, default: []
      t.boolean :affects_all_monitors, default: false
      
      # Status
      t.string :status, default: 'scheduled'     # scheduled, in_progress, completed, cancelled
      
      # Notifications
      t.boolean :notify_subscribers, default: true
      t.integer :notify_before_minutes, default: 60
      t.boolean :notified, default: false
      
      t.timestamps
      
      t.index [:platform_project_id, :starts_at]
      t.index :status
    end
  end
end

# db/migrate/008_create_ssl_certificates.rb

class CreateSslCertificates < ActiveRecord::Migration[8.0]
  def change
    create_table :ssl_certificates, id: :uuid do |t|
      t.references :monitor, type: :uuid, null: false, foreign_key: true
      
      t.string :domain, null: false
      t.string :issuer
      t.string :subject
      t.string :serial_number
      
      t.datetime :issued_at
      t.datetime :expires_at
      
      t.boolean :valid, default: true
      t.string :validation_error
      
      t.string :fingerprint_sha256
      t.string :public_key_algorithm
      t.integer :public_key_bits
      
      t.datetime :last_checked_at
      
      t.timestamps
      
      t.index [:monitor_id, :expires_at]
      t.index :expires_at
    end
  end
end

# db/migrate/009_create_status_subscriptions.rb

class CreateStatusSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :status_subscriptions, id: :uuid do |t|
      t.references :status_page, type: :uuid, null: false, foreign_key: true
      
      t.string :email
      t.string :phone                            # For SMS
      t.string :webhook_url                      # For webhook notifications
      
      t.string :channel, null: false             # email, sms, webhook
      t.boolean :confirmed, default: false
      t.string :confirmation_token
      t.datetime :confirmed_at
      
      # Preferences
      t.boolean :notify_incidents, default: true
      t.boolean :notify_maintenance, default: true
      t.string :severity_filter, array: true, default: ['minor', 'major', 'critical']
      
      t.timestamps
      
      t.index [:status_page_id, :email]
      t.index :confirmation_token
    end
  end
end

# db/migrate/010_create_alert_rules.rb

class CreateAlertRules < ActiveRecord::Migration[8.0]
  def change
    create_table :alert_rules, id: :uuid do |t|
      t.references :monitor, type: :uuid, null: false, foreign_key: true
      
      t.string :name, null: false
      t.boolean :enabled, default: true
      
      # Condition
      t.string :condition_type, null: false      # status_change, response_time, ssl_expiry
      t.jsonb :condition_config, default: {}
      # {
      #   status_change: { from: "up", to: "down" },
      #   response_time: { operator: "gt", value: 1000 },
      #   ssl_expiry: { days_before: 30 }
      # }
      
      # Notification via Signal
      t.uuid :signal_alert_id                    # Link to Signal alert
      
      t.timestamps
      
      t.index [:monitor_id, :enabled]
    end
  end
end
```

---

## Models

```ruby
# app/models/monitor.rb

class Monitor < ApplicationRecord
  belongs_to :platform_project, class_name: 'Platform::Project'
  
  has_many :check_results, dependent: :destroy
  has_many :incidents, dependent: :destroy
  has_many :status_page_monitors, dependent: :destroy
  has_many :status_pages, through: :status_page_monitors
  has_many :alert_rules, dependent: :destroy
  has_one :ssl_certificate, dependent: :destroy
  
  validates :name, presence: true
  validates :monitor_type, presence: true, inclusion: { in: %w[http tcp dns ssl ping] }
  validates :url, presence: true, if: -> { monitor_type == 'http' }
  validates :host, presence: true, if: -> { monitor_type.in?(%w[tcp dns ping]) }
  validates :interval_seconds, numericality: { greater_than_or_equal_to: 30 }
  
  scope :enabled, -> { where(enabled: true, paused: false) }
  scope :due_for_check, -> { enabled.where('last_check_at IS NULL OR last_check_at < ?', Time.current - interval_seconds.seconds) }
  scope :by_status, ->(status) { where(status: status) }
  
  enum :status, { unknown: 'unknown', up: 'up', down: 'down', degraded: 'degraded' }
  
  def check!
    checker = checker_class.new(self)
    result = checker.check
    
    process_result(result)
    result
  end
  
  def uptime(period: 30.days)
    UptimeCalculator.new(self, period: period).calculate
  end
  
  def average_response_time(period: 24.hours)
    check_results
      .where('checked_at > ?', period.ago)
      .where(status: 'up')
      .average(:response_time_ms)
      &.round || 0
  end
  
  def response_time_series(period: 24.hours, interval: '1 hour')
    check_results
      .where('checked_at > ?', period.ago)
      .group("time_bucket('#{interval}', checked_at)")
      .average(:response_time_ms)
      .transform_values(&:round)
  end
  
  private
  
  def checker_class
    case monitor_type
    when 'http' then Checkers::HttpChecker
    when 'tcp' then Checkers::TcpChecker
    when 'dns' then Checkers::DnsChecker
    when 'ssl' then Checkers::SslChecker
    when 'ping' then Checkers::PingChecker
    end
  end
  
  def process_result(result)
    previous_status = status
    
    if result.success?
      self.consecutive_successes += 1
      self.consecutive_failures = 0
      self.last_up_at = Time.current
      
      if consecutive_successes >= recovery_threshold
        self.status = 'up'
        resolve_active_incident if previous_status != 'up'
      end
    else
      self.consecutive_failures += 1
      self.consecutive_successes = 0
      self.last_down_at = Time.current
      
      if consecutive_failures >= confirmation_threshold
        self.status = 'down'
        create_incident if previous_status == 'up'
      end
    end
    
    self.last_check_at = Time.current
    save!
    
    # Broadcast status change
    broadcast_status if status_changed?
  end
  
  def create_incident
    incidents.create!(
      title: "#{name} is down",
      status: 'investigating',
      severity: 'major',
      started_at: last_down_at
    )
  end
  
  def resolve_active_incident
    incidents.where(status: %w[investigating identified monitoring]).find_each do |incident|
      incident.resolve!
    end
  end
  
  def broadcast_status
    ActionCable.server.broadcast(
      "monitor_#{id}",
      { status: status, last_check_at: last_check_at }
    )
  end
end

# app/models/check_result.rb

class CheckResult < ApplicationRecord
  belongs_to :monitor
  
  validates :checked_at, presence: true
  validates :region, presence: true
  validates :status, presence: true
  
  scope :recent, -> { order(checked_at: :desc) }
  scope :successful, -> { where(status: 'up') }
  scope :failed, -> { where(status: 'down') }
  scope :in_region, ->(region) { where(region: region) }
  
  def success?
    status == 'up'
  end
  
  def failed?
    status == 'down'
  end
end

# app/models/incident.rb

class Incident < ApplicationRecord
  belongs_to :monitor
  
  has_many :updates, class_name: 'IncidentUpdate', dependent: :destroy
  
  validates :title, presence: true
  validates :status, presence: true
  validates :started_at, presence: true
  
  scope :active, -> { where(status: %w[investigating identified monitoring]) }
  scope :resolved, -> { where(status: 'resolved') }
  scope :recent, -> { order(started_at: :desc) }
  
  after_create :create_initial_update
  after_create :notify_subscribers
  
  def resolve!(notes: nil)
    update!(
      status: 'resolved',
      resolved_at: Time.current,
      duration_seconds: Time.current - started_at,
      resolution_notes: notes
    )
    
    add_update('resolved', notes || 'This incident has been resolved.')
    notify_resolution
  end
  
  def add_update(new_status, message, user: 'system')
    updates.create!(
      status: new_status,
      message: message,
      created_by: user
    )
    
    update!(status: new_status)
    broadcast_update
  end
  
  def duration
    if resolved_at
      resolved_at - started_at
    else
      Time.current - started_at
    end
  end
  
  def duration_humanized
    ActiveSupport::Duration.build(duration.to_i).inspect
  end
  
  private
  
  def create_initial_update
    updates.create!(
      status: 'investigating',
      message: "We are investigating issues with #{monitor.name}.",
      created_by: 'system'
    )
  end
  
  def notify_subscribers
    IncidentNotificationJob.perform_later(id, 'created')
  end
  
  def notify_resolution
    IncidentNotificationJob.perform_later(id, 'resolved')
  end
  
  def broadcast_update
    monitor.status_pages.each do |status_page|
      ActionCable.server.broadcast(
        "status_page_#{status_page.id}",
        { type: 'incident_update', incident_id: id, status: status }
      )
    end
  end
end

# app/models/status_page.rb

class StatusPage < ApplicationRecord
  belongs_to :platform_project, class_name: 'Platform::Project'
  
  has_many :status_page_monitors, dependent: :destroy
  has_many :monitors, through: :status_page_monitors
  has_many :subscriptions, class_name: 'StatusSubscription', dependent: :destroy
  
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }
  
  before_validation :generate_slug, if: -> { slug.blank? }
  
  def calculate_status
    statuses = monitors.pluck(:status)
    
    if statuses.all? { |s| s == 'up' }
      'operational'
    elsif statuses.all? { |s| s == 'down' }
      'major_outage'
    elsif statuses.any? { |s| s == 'down' }
      'partial_outage'
    elsif statuses.any? { |s| s == 'degraded' }
      'degraded'
    else
      'operational'
    end
  end
  
  def update_status!
    update!(current_status: calculate_status)
  end
  
  def monitors_by_group
    status_page_monitors
      .includes(:monitor)
      .visible
      .ordered
      .group_by(&:group_name)
  end
  
  def active_incidents
    monitors.flat_map { |m| m.incidents.active }
  end
  
  def recent_incidents(limit: 10)
    Incident
      .joins(:monitor)
      .where(monitor_id: monitor_ids)
      .resolved
      .recent
      .limit(limit)
  end
  
  def overall_uptime(days: 90)
    uptimes = monitors.map { |m| m.uptime(period: days.days) }
    return 100.0 if uptimes.empty?
    
    (uptimes.sum / uptimes.size).round(2)
  end
  
  private
  
  def generate_slug
    self.slug = name.parameterize
  end
end
```

---

## Checkers

```ruby
# app/services/checkers/base_checker.rb

module Checkers
  class BaseChecker
    attr_reader :monitor
    
    def initialize(monitor)
      @monitor = monitor
    end
    
    def check
      started_at = Time.current
      
      begin
        result = perform_check
        
        CheckResult.create!(
          monitor: monitor,
          checked_at: Time.current,
          region: current_region,
          status: result[:success] ? 'up' : 'down',
          response_time_ms: result[:response_time_ms],
          dns_time_ms: result[:dns_time_ms],
          connect_time_ms: result[:connect_time_ms],
          tls_time_ms: result[:tls_time_ms],
          ttfb_ms: result[:ttfb_ms],
          status_code: result[:status_code],
          response_size_bytes: result[:response_size_bytes],
          error_message: result[:error_message],
          error_type: result[:error_type]
        )
      rescue => e
        CheckResult.create!(
          monitor: monitor,
          checked_at: Time.current,
          region: current_region,
          status: 'down',
          response_time_ms: ((Time.current - started_at) * 1000).to_i,
          error_message: e.message,
          error_type: 'exception'
        )
      end
    end
    
    protected
    
    def perform_check
      raise NotImplementedError
    end
    
    def current_region
      ENV.fetch('BEACON_REGION', 'nyc')
    end
  end
end

# app/services/checkers/http_checker.rb

module Checkers
  class HttpChecker < BaseChecker
    def perform_check
      timings = {}
      
      # Configure HTTP client
      conn = Faraday.new(url: monitor.url) do |f|
        f.options.timeout = monitor.timeout_seconds
        f.options.open_timeout = 10
        f.ssl.verify = monitor.verify_ssl
        
        # Add authentication
        apply_auth(f)
        
        # Add custom headers
        monitor.headers.each { |k, v| f.headers[k] = v }
        
        f.response :follow_redirects if monitor.follow_redirects
        
        # Instrumentation for timing
        f.use :instrumentation do |request|
          timings[:dns_start] = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end
      end
      
      # Make request
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      
      response = case monitor.http_method.upcase
                 when 'GET' then conn.get
                 when 'POST' then conn.post(nil, monitor.body)
                 when 'HEAD' then conn.head
                 when 'PUT' then conn.put(nil, monitor.body)
                 when 'DELETE' then conn.delete
                 end
      
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response_time_ms = ((end_time - start_time) * 1000).to_i
      
      # Check success criteria
      success = check_success(response)
      
      {
        success: success,
        response_time_ms: response_time_ms,
        status_code: response.status,
        response_size_bytes: response.body&.bytesize || 0,
        error_message: success ? nil : determine_error(response)
      }
    rescue Faraday::TimeoutError
      {
        success: false,
        response_time_ms: monitor.timeout_seconds * 1000,
        error_message: 'Request timed out',
        error_type: 'timeout'
      }
    rescue Faraday::ConnectionFailed => e
      {
        success: false,
        error_message: e.message,
        error_type: 'connection_refused'
      }
    rescue Faraday::SSLError => e
      {
        success: false,
        error_message: e.message,
        error_type: 'ssl_error'
      }
    end
    
    private
    
    def apply_auth(conn)
      case monitor.auth_type
      when 'basic'
        conn.basic_auth(
          monitor.auth_config['username'],
          monitor.auth_config['password']
        )
      when 'bearer'
        conn.headers['Authorization'] = "Bearer #{monitor.auth_config['token']}"
      when 'header'
        conn.headers[monitor.auth_config['header_name']] = monitor.auth_config['header_value']
      end
    end
    
    def check_success(response)
      # Check status code
      return false unless response.status == monitor.expected_status
      
      # Check body content if specified
      if monitor.expected_body.present?
        return false unless response.body.include?(monitor.expected_body)
      end
      
      true
    end
    
    def determine_error(response)
      if response.status != monitor.expected_status
        "Expected status #{monitor.expected_status}, got #{response.status}"
      elsif monitor.expected_body.present? && !response.body.include?(monitor.expected_body)
        "Expected body to contain '#{monitor.expected_body}'"
      else
        'Unknown error'
      end
    end
  end
end

# app/services/checkers/ssl_checker.rb

module Checkers
  class SslChecker < BaseChecker
    def perform_check
      uri = URI.parse(monitor.url)
      host = uri.host
      port = uri.port || 443
      
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      
      # Connect and get certificate
      tcp_client = TCPSocket.new(host, port)
      ssl_context = OpenSSL::SSL::SSLContext.new
      ssl_client = OpenSSL::SSL::SSLSocket.new(tcp_client, ssl_context)
      ssl_client.hostname = host
      ssl_client.connect
      
      cert = ssl_client.peer_cert
      chain = ssl_client.peer_cert_chain
      
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      
      ssl_client.close
      tcp_client.close
      
      # Analyze certificate
      expires_at = cert.not_after
      days_until_expiry = ((expires_at - Time.current) / 1.day).to_i
      
      # Update SSL certificate record
      update_ssl_certificate(cert)
      
      # Update monitor's SSL expiry
      monitor.update!(ssl_expiry_at: expires_at)
      
      {
        success: valid_certificate?(cert, days_until_expiry),
        response_time_ms: ((end_time - start_time) * 1000).to_i,
        ssl_issuer: cert.issuer.to_s,
        ssl_expires_at: expires_at,
        ssl_valid: valid_certificate?(cert, days_until_expiry),
        error_message: certificate_error(cert, days_until_expiry)
      }
    rescue => e
      {
        success: false,
        error_message: e.message,
        error_type: 'ssl_error'
      }
    end
    
    private
    
    def valid_certificate?(cert, days_until_expiry)
      cert.not_before <= Time.current &&
        cert.not_after >= Time.current &&
        days_until_expiry > 0
    end
    
    def certificate_error(cert, days_until_expiry)
      if days_until_expiry <= 0
        'Certificate has expired'
      elsif days_until_expiry <= monitor.ssl_expiry_warn_days
        "Certificate expires in #{days_until_expiry} days"
      elsif cert.not_before > Time.current
        'Certificate is not yet valid'
      else
        nil
      end
    end
    
    def update_ssl_certificate(cert)
      monitor.ssl_certificate&.destroy
      
      monitor.create_ssl_certificate!(
        domain: URI.parse(monitor.url).host,
        issuer: cert.issuer.to_s,
        subject: cert.subject.to_s,
        serial_number: cert.serial.to_s,
        issued_at: cert.not_before,
        expires_at: cert.not_after,
        valid: true,
        fingerprint_sha256: OpenSSL::Digest::SHA256.hexdigest(cert.to_der),
        public_key_algorithm: cert.public_key.class.name,
        public_key_bits: cert.public_key.n.num_bits,
        last_checked_at: Time.current
      )
    end
  end
end

# app/services/checkers/tcp_checker.rb

module Checkers
  class TcpChecker < BaseChecker
    def perform_check
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      
      socket = Socket.tcp(
        monitor.host,
        monitor.port,
        connect_timeout: monitor.timeout_seconds
      )
      
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      socket.close
      
      {
        success: true,
        response_time_ms: ((end_time - start_time) * 1000).to_i,
        connect_time_ms: ((end_time - start_time) * 1000).to_i
      }
    rescue Errno::ECONNREFUSED
      {
        success: false,
        error_message: "Connection refused on port #{monitor.port}",
        error_type: 'connection_refused'
      }
    rescue Errno::ETIMEDOUT, Timeout::Error
      {
        success: false,
        error_message: 'Connection timed out',
        error_type: 'timeout'
      }
    rescue SocketError => e
      {
        success: false,
        error_message: e.message,
        error_type: 'dns_error'
      }
    end
  end
end

# app/services/checkers/dns_checker.rb

module Checkers
  class DnsChecker < BaseChecker
    def perform_check
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      
      resolver = Resolv::DNS.new
      resolver.timeouts = monitor.timeout_seconds
      
      addresses = resolver.getaddresses(monitor.host)
      
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      
      if addresses.any?
        {
          success: true,
          response_time_ms: ((end_time - start_time) * 1000).to_i,
          dns_time_ms: ((end_time - start_time) * 1000).to_i,
          resolved_ip: addresses.first.to_s,
          resolved_ips: addresses.map(&:to_s)
        }
      else
        {
          success: false,
          error_message: 'No DNS records found',
          error_type: 'dns_error'
        }
      end
    rescue Resolv::ResolvError => e
      {
        success: false,
        error_message: e.message,
        error_type: 'dns_error'
      }
    rescue Resolv::ResolvTimeout
      {
        success: false,
        error_message: 'DNS resolution timed out',
        error_type: 'timeout'
      }
    end
  end
end

# app/services/checkers/ping_checker.rb

module Checkers
  class PingChecker < BaseChecker
    def perform_check
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      
      # Use system ping command
      result = system("ping -c 1 -W #{monitor.timeout_seconds} #{monitor.host} > /dev/null 2>&1")
      
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      
      if result
        {
          success: true,
          response_time_ms: ((end_time - start_time) * 1000).to_i
        }
      else
        {
          success: false,
          error_message: 'Host unreachable',
          error_type: 'ping_failed'
        }
      end
    end
  end
end
```

---

## Services

```ruby
# app/services/uptime_calculator.rb

class UptimeCalculator
  def initialize(monitor, period: 30.days)
    @monitor = monitor
    @period = period
  end
  
  def calculate
    results = @monitor.check_results
                      .where('checked_at > ?', @period.ago)
                      .group(:status)
                      .count
    
    total = results.values.sum
    return 100.0 if total.zero?
    
    up_count = results['up'] || 0
    ((up_count.to_f / total) * 100).round(2)
  end
  
  def daily_breakdown
    @monitor.check_results
            .where('checked_at > ?', @period.ago)
            .group("DATE(checked_at)")
            .group(:status)
            .count
            .transform_keys { |k| [k[0], k[1]] }
  end
  
  def uptime_bars(days: 90)
    # Returns array of daily uptime percentages for visualization
    (0...days).map do |i|
      date = i.days.ago.to_date
      results = @monitor.check_results
                        .where('DATE(checked_at) = ?', date)
                        .group(:status)
                        .count
      
      total = results.values.sum
      next { date: date, uptime: nil, status: 'no_data' } if total.zero?
      
      up_count = results['up'] || 0
      uptime = ((up_count.to_f / total) * 100).round(2)
      
      {
        date: date,
        uptime: uptime,
        status: uptime_status(uptime)
      }
    end.reverse
  end
  
  private
  
  def uptime_status(uptime)
    case uptime
    when 100 then 'operational'
    when 99..100 then 'degraded'
    when 95..99 then 'partial_outage'
    else 'major_outage'
    end
  end
end

# app/services/status_calculator.rb

class StatusCalculator
  STATUSES = {
    operational: { priority: 0, label: 'All Systems Operational', color: '#10B981' },
    degraded: { priority: 1, label: 'Degraded Performance', color: '#F59E0B' },
    partial_outage: { priority: 2, label: 'Partial Outage', color: '#F97316' },
    major_outage: { priority: 3, label: 'Major Outage', color: '#EF4444' }
  }.freeze
  
  def initialize(status_page)
    @status_page = status_page
  end
  
  def overall_status
    @status_page.calculate_status
  end
  
  def status_info
    STATUSES[overall_status.to_sym]
  end
  
  def component_statuses
    @status_page.status_page_monitors.includes(:monitor).map do |spm|
      {
        name: spm.display_name || spm.monitor.name,
        group: spm.group_name,
        status: spm.monitor.status,
        uptime: spm.monitor.uptime(period: 90.days),
        response_time: spm.monitor.average_response_time
      }
    end
  end
end

# app/services/incident_manager.rb

class IncidentManager
  def initialize(monitor)
    @monitor = monitor
  end
  
  def create_incident(severity: 'major')
    incident = @monitor.incidents.create!(
      title: "#{@monitor.name} is experiencing issues",
      status: 'investigating',
      severity: severity,
      started_at: Time.current,
      affected_regions: @monitor.regions
    )
    
    notify_via_signal(incident)
    notify_status_page_subscribers(incident)
    
    incident
  end
  
  def resolve_incident(incident, notes: nil)
    incident.resolve!(notes: notes)
    
    notify_via_signal(incident, event: 'resolved')
    notify_status_page_subscribers(incident, event: 'resolved')
  end
  
  private
  
  def notify_via_signal(incident, event: 'created')
    # Integration with Signal alerting
    return unless defined?(Signal::Client)
    
    Signal::Client.trigger_alert(
      source: 'beacon',
      title: incident.title,
      severity: incident.severity,
      data: {
        monitor_id: @monitor.id,
        monitor_name: @monitor.name,
        incident_id: incident.id,
        event: event
      }
    )
  end
  
  def notify_status_page_subscribers(incident, event: 'created')
    @monitor.status_pages.each do |status_page|
      status_page.subscriptions.confirmed.find_each do |subscription|
        IncidentNotificationJob.perform_later(
          subscription.id,
          incident.id,
          event
        )
      end
    end
  end
end
```

---

## Jobs

```ruby
# app/jobs/execute_check_job.rb

class ExecuteCheckJob < ApplicationJob
  queue_as :checks
  
  def perform(monitor_id)
    monitor = Monitor.find(monitor_id)
    return unless monitor.enabled? && !monitor.paused?
    
    monitor.check!
    
    # Schedule next check
    ExecuteCheckJob
      .set(wait: monitor.interval_seconds.seconds)
      .perform_later(monitor_id)
  end
end

# app/jobs/schedule_checks_job.rb

class ScheduleChecksJob < ApplicationJob
  queue_as :scheduler
  
  def perform
    Monitor.enabled.find_each do |monitor|
      # Check if already scheduled
      next if check_scheduled?(monitor)
      
      ExecuteCheckJob.perform_later(monitor.id)
    end
  end
  
  private
  
  def check_scheduled?(monitor)
    # Check if job is already in queue
    SolidQueue::Job.where(
      "arguments LIKE ?",
      "%monitor_id: #{monitor.id}%"
    ).exists?
  end
end

# app/jobs/ssl_expiry_check_job.rb

class SslExpiryCheckJob < ApplicationJob
  queue_as :default
  
  def perform
    Monitor.where(monitor_type: 'http')
           .where.not(ssl_expiry_at: nil)
           .where('ssl_expiry_at < ?', 30.days.from_now)
           .find_each do |monitor|
      
      days_left = ((monitor.ssl_expiry_at - Time.current) / 1.day).to_i
      
      # Notify based on urgency
      if days_left <= 7
        notify_ssl_expiry(monitor, days_left, severity: 'critical')
      elsif days_left <= 14
        notify_ssl_expiry(monitor, days_left, severity: 'major')
      elsif days_left <= 30
        notify_ssl_expiry(monitor, days_left, severity: 'minor')
      end
    end
  end
  
  private
  
  def notify_ssl_expiry(monitor, days_left, severity:)
    Signal::Client.trigger_alert(
      source: 'beacon',
      title: "SSL certificate expiring soon: #{monitor.name}",
      message: "Certificate expires in #{days_left} days",
      severity: severity,
      data: {
        monitor_id: monitor.id,
        monitor_name: monitor.name,
        ssl_expiry_at: monitor.ssl_expiry_at,
        days_left: days_left
      }
    )
  end
end

# app/jobs/incident_notification_job.rb

class IncidentNotificationJob < ApplicationJob
  queue_as :notifications
  
  def perform(subscription_id, incident_id, event)
    subscription = StatusSubscription.find(subscription_id)
    incident = Incident.find(incident_id)
    
    case subscription.channel
    when 'email'
      send_email(subscription, incident, event)
    when 'sms'
      send_sms(subscription, incident, event)
    when 'webhook'
      send_webhook(subscription, incident, event)
    end
  end
  
  private
  
  def send_email(subscription, incident, event)
    IncidentMailer.notification(
      email: subscription.email,
      incident: incident,
      event: event
    ).deliver_now
  end
  
  def send_sms(subscription, incident, event)
    # Twilio integration
    Twilio::Client.send_sms(
      to: subscription.phone,
      body: build_sms_message(incident, event)
    )
  end
  
  def send_webhook(subscription, incident, event)
    Faraday.post(subscription.webhook_url) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        event: event,
        incident: {
          id: incident.id,
          title: incident.title,
          status: incident.status,
          severity: incident.severity,
          started_at: incident.started_at,
          resolved_at: incident.resolved_at
        },
        monitor: {
          id: incident.monitor_id,
          name: incident.monitor.name
        }
      }.to_json
    end
  end
  
  def build_sms_message(incident, event)
    case event
    when 'created'
      "🚨 #{incident.title} - #{incident.severity.upcase}"
    when 'resolved'
      "✅ Resolved: #{incident.title}"
    else
      "📢 Update: #{incident.title} - #{incident.status}"
    end
  end
end
```

---

## Controllers

```ruby
# app/controllers/api/v1/monitors_controller.rb

module Api
  module V1
    class MonitorsController < BaseController
      # GET /api/v1/monitors
      def index
        monitors = current_project.monitors
        
        if params[:status].present?
          monitors = monitors.by_status(params[:status])
        end
        
        render json: MonitorSerializer.new(monitors).serializable_hash
      end
      
      # POST /api/v1/monitors
      def create
        monitor = current_project.monitors.create!(monitor_params)
        
        # Start monitoring
        ExecuteCheckJob.perform_later(monitor.id)
        
        render json: MonitorSerializer.new(monitor).serializable_hash, status: :created
      end
      
      # GET /api/v1/monitors/:id
      def show
        monitor = current_project.monitors.find(params[:id])
        
        render json: MonitorSerializer.new(
          monitor,
          include: [:recent_checks, :active_incidents]
        ).serializable_hash
      end
      
      # PATCH /api/v1/monitors/:id
      def update
        monitor = current_project.monitors.find(params[:id])
        monitor.update!(monitor_params)
        
        render json: MonitorSerializer.new(monitor).serializable_hash
      end
      
      # DELETE /api/v1/monitors/:id
      def destroy
        monitor = current_project.monitors.find(params[:id])
        monitor.destroy!
        
        head :no_content
      end
      
      # POST /api/v1/monitors/:id/pause
      def pause
        monitor = current_project.monitors.find(params[:id])
        monitor.update!(paused: true)
        
        render json: { paused: true }
      end
      
      # POST /api/v1/monitors/:id/resume
      def resume
        monitor = current_project.monitors.find(params[:id])
        monitor.update!(paused: false)
        
        ExecuteCheckJob.perform_later(monitor.id)
        
        render json: { paused: false }
      end
      
      # GET /api/v1/monitors/:id/uptime
      def uptime
        monitor = current_project.monitors.find(params[:id])
        period = (params[:days] || 30).to_i.days
        
        calculator = UptimeCalculator.new(monitor, period: period)
        
        render json: {
          uptime_percentage: calculator.calculate,
          uptime_bars: calculator.uptime_bars(days: period / 1.day)
        }
      end
      
      # GET /api/v1/monitors/:id/response_times
      def response_times
        monitor = current_project.monitors.find(params[:id])
        period = (params[:hours] || 24).to_i.hours
        
        render json: {
          average: monitor.average_response_time(period: period),
          series: monitor.response_time_series(period: period)
        }
      end
      
      private
      
      def monitor_params
        params.require(:monitor).permit(
          :name, :monitor_type, :url, :host, :port,
          :interval_seconds, :timeout_seconds,
          :http_method, :expected_status, :expected_body,
          :follow_redirects, :verify_ssl,
          :auth_type, :confirmation_threshold, :recovery_threshold,
          :ssl_expiry_warn_days,
          regions: [],
          headers: {},
          auth_config: {}
        )
      end
    end
  end
end

# app/controllers/public/status_controller.rb

module Public
  class StatusController < ApplicationController
    skip_before_action :authenticate!
    
    # GET /status/:slug
    def show
      @status_page = StatusPage.find_by!(slug: params[:slug])
      
      return head :not_found unless @status_page.public?
      
      calculator = StatusCalculator.new(@status_page)
      
      render json: {
        name: @status_page.name,
        status: calculator.overall_status,
        status_info: calculator.status_info,
        components: calculator.component_statuses,
        active_incidents: @status_page.active_incidents.map { |i| IncidentSerializer.new(i).as_json },
        recent_incidents: @status_page.recent_incidents.map { |i| IncidentSerializer.new(i).as_json },
        overall_uptime: @status_page.overall_uptime,
        updated_at: Time.current
      }
    end
  end
end
```

---

## MCP Tools

```ruby
# lib/beacon/mcp/tools/list_monitors.rb

module Beacon
  module Mcp
    module Tools
      class ListMonitors < BaseTool
        TOOL_NAME = 'beacon_list_monitors'
        DESCRIPTION = 'List all uptime monitors and their current status'
        
        SCHEMA = {
          type: 'object',
          properties: {
            status: {
              type: 'string',
              enum: ['up', 'down', 'degraded', 'unknown'],
              description: 'Filter by status'
            }
          }
        }.freeze
        
        def call(args)
          monitors = project.monitors
          monitors = monitors.by_status(args[:status]) if args[:status]
          
          {
            monitors: monitors.map do |m|
              {
                id: m.id,
                name: m.name,
                type: m.monitor_type,
                url: m.url || m.host,
                status: m.status,
                uptime_30d: m.uptime(period: 30.days),
                avg_response_time: m.average_response_time,
                last_check: m.last_check_at
              }
            end,
            summary: {
              total: monitors.count,
              up: monitors.up.count,
              down: monitors.down.count,
              degraded: monitors.degraded.count
            }
          }
        end
      end
      
      class CheckStatus < BaseTool
        TOOL_NAME = 'beacon_check_status'
        DESCRIPTION = 'Check the current status of a specific monitor'
        
        SCHEMA = {
          type: 'object',
          properties: {
            monitor_name: {
              type: 'string',
              description: 'Name or URL of the monitor'
            }
          },
          required: ['monitor_name']
        }.freeze
        
        def call(args)
          monitor = find_monitor(args[:monitor_name])
          
          {
            name: monitor.name,
            status: monitor.status,
            uptime_24h: monitor.uptime(period: 24.hours),
            uptime_7d: monitor.uptime(period: 7.days),
            uptime_30d: monitor.uptime(period: 30.days),
            avg_response_time: monitor.average_response_time,
            last_check: monitor.last_check_at,
            last_down: monitor.last_down_at,
            active_incidents: monitor.incidents.active.count,
            ssl_expires: monitor.ssl_expiry_at
          }
        end
        
        private
        
        def find_monitor(name_or_url)
          project.monitors.find_by!(name: name_or_url) ||
            project.monitors.find_by!(url: name_or_url)
        end
      end
      
      class CreateMonitor < BaseTool
        TOOL_NAME = 'beacon_create_monitor'
        DESCRIPTION = 'Create a new uptime monitor'
        
        SCHEMA = {
          type: 'object',
          properties: {
            name: {
              type: 'string',
              description: 'Name for the monitor'
            },
            url: {
              type: 'string',
              description: 'URL to monitor'
            },
            type: {
              type: 'string',
              enum: ['http', 'tcp', 'dns', 'ssl', 'ping'],
              default: 'http'
            },
            interval: {
              type: 'integer',
              description: 'Check interval in seconds',
              default: 60
            }
          },
          required: ['name', 'url']
        }.freeze
        
        def call(args)
          monitor = project.monitors.create!(
            name: args[:name],
            url: args[:url],
            monitor_type: args[:type] || 'http',
            interval_seconds: args[:interval] || 60
          )
          
          ExecuteCheckJob.perform_later(monitor.id)
          
          {
            created: true,
            monitor_id: monitor.id,
            name: monitor.name,
            message: "Monitor '#{monitor.name}' created. First check running now."
          }
        end
      end
      
      class GetUptime < BaseTool
        TOOL_NAME = 'beacon_get_uptime'
        DESCRIPTION = 'Get uptime statistics for monitors'
        
        SCHEMA = {
          type: 'object',
          properties: {
            monitor_name: {
              type: 'string',
              description: 'Specific monitor (optional, returns all if not specified)'
            },
            period: {
              type: 'string',
              enum: ['24h', '7d', '30d', '90d'],
              default: '30d'
            }
          }
        }.freeze
        
        def call(args)
          period = parse_period(args[:period])
          
          if args[:monitor_name]
            monitor = project.monitors.find_by!(name: args[:monitor_name])
            single_monitor_uptime(monitor, period)
          else
            all_monitors_uptime(period)
          end
        end
        
        private
        
        def parse_period(period_str)
          case period_str
          when '24h' then 24.hours
          when '7d' then 7.days
          when '30d' then 30.days
          when '90d' then 90.days
          else 30.days
          end
        end
        
        def single_monitor_uptime(monitor, period)
          calculator = UptimeCalculator.new(monitor, period: period)
          
          {
            monitor: monitor.name,
            uptime: calculator.calculate,
            daily_breakdown: calculator.uptime_bars
          }
        end
        
        def all_monitors_uptime(period)
          {
            monitors: project.monitors.map do |m|
              {
                name: m.name,
                uptime: m.uptime(period: period),
                status: m.status
              }
            end,
            overall: calculate_overall_uptime(period)
          }
        end
        
        def calculate_overall_uptime(period)
          uptimes = project.monitors.map { |m| m.uptime(period: period) }
          return 100.0 if uptimes.empty?
          (uptimes.sum / uptimes.size).round(2)
        end
      end
      
      class ListIncidents < BaseTool
        TOOL_NAME = 'beacon_list_incidents'
        DESCRIPTION = 'List incidents (outages)'
        
        SCHEMA = {
          type: 'object',
          properties: {
            status: {
              type: 'string',
              enum: ['active', 'resolved', 'all'],
              default: 'active'
            },
            limit: {
              type: 'integer',
              default: 10
            }
          }
        }.freeze
        
        def call(args)
          incidents = Incident.joins(:monitor)
                              .where(monitors: { platform_project_id: project.id })
          
          case args[:status]
          when 'active'
            incidents = incidents.active
          when 'resolved'
            incidents = incidents.resolved
          end
          
          incidents = incidents.recent.limit(args[:limit] || 10)
          
          {
            incidents: incidents.map do |i|
              {
                id: i.id,
                title: i.title,
                status: i.status,
                severity: i.severity,
                monitor: i.monitor.name,
                started_at: i.started_at,
                resolved_at: i.resolved_at,
                duration: i.duration_humanized
              }
            end
          }
        end
      end
    end
  end
end
```

---

## Routes

```ruby
# config/routes.rb

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :monitors do
        member do
          post :pause
          post :resume
          get :uptime
          get :response_times
        end
        
        resources :checks, only: [:index]
        resources :incidents, only: [:index, :show, :update]
      end
      
      resources :status_pages do
        resources :monitors, controller: 'status_page_monitors', only: [:index, :create, :destroy]
        resources :subscriptions, only: [:index, :create, :destroy]
      end
      
      resources :incidents, only: [:index, :show, :update] do
        resources :updates, only: [:index, :create]
      end
      
      resources :maintenance_windows
    end
  end
  
  # Public status page
  get 'status/:slug', to: 'public/status#show'
  get 'status/:slug/badge', to: 'public/status#badge'
  
  # Subscription confirmation
  get 'subscriptions/:token/confirm', to: 'subscriptions#confirm'
  
  # Health check
  get 'health', to: 'health#show'
end
```

---

## Docker Compose

```yaml
# docker-compose.yml

version: '3.8'

services:
  web:
    build: .
    ports:
      - "3008:3000"
    environment:
      - DATABASE_URL=postgres://postgres:postgres@db:5432/beacon
      - REDIS_URL=redis://redis:6379
      - BEACON_REGION=nyc
    depends_on:
      - db
      - redis
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.beacon.rule=Host(`beacon.brainzlab.localhost`)"

  worker:
    build: .
    command: bundle exec rake solid_queue:start
    environment:
      - DATABASE_URL=postgres://postgres:postgres@db:5432/beacon
      - REDIS_URL=redis://redis:6379
      - BEACON_REGION=nyc
    depends_on:
      - db
      - redis

  scheduler:
    build: .
    command: bundle exec rake beacon:scheduler
    environment:
      - DATABASE_URL=postgres://postgres:postgres@db:5432/beacon
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis

  db:
    image: timescale/timescaledb:latest-pg16
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=beacon
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5438:5432"

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

---

## Multi-Region Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        MULTI-REGION MONITORING                               │
│                                                                              │
│   ┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌───────────┐ │
│   │   NYC       │     │   LONDON    │     │  SINGAPORE  │     │  SYDNEY   │ │
│   │   Worker    │     │   Worker    │     │   Worker    │     │  Worker   │ │
│   │             │     │             │     │             │     │           │ │
│   │ Fly.io/NYC  │     │ Fly.io/LHR  │     │ Fly.io/SIN  │     │ Fly.io/SYD│ │
│   └──────┬──────┘     └──────┬──────┘     └──────┬──────┘     └─────┬─────┘ │
│          │                   │                   │                  │       │
│          └───────────────────┴─────────┬─────────┴──────────────────┘       │
│                                        │                                     │
│                                        ▼                                     │
│                          ┌─────────────────────────┐                        │
│                          │    Central API          │                        │
│                          │    (Primary Region)     │                        │
│                          │                         │                        │
│                          │  - Stores results       │                        │
│                          │  - Calculates uptime    │                        │
│                          │  - Triggers alerts      │                        │
│                          │  - Manages incidents    │                        │
│                          └─────────────────────────┘                        │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Summary

### Beacon Features

| Feature | Description |
|---------|-------------|
| **HTTP Monitoring** | Status codes, response time, body checks |
| **TCP Monitoring** | Port connectivity checks |
| **DNS Monitoring** | Resolution, propagation |
| **SSL Monitoring** | Certificate expiry, validity |
| **Ping Monitoring** | ICMP reachability |
| **Multi-Region** | Check from NYC, London, Singapore, Sydney |
| **Status Pages** | Public status page with branding |
| **Incidents** | Automatic incident creation & management |
| **Maintenance Windows** | Scheduled maintenance with notifications |
| **Subscriptions** | Email, SMS, webhook notifications |

### MCP Tools

| Tool | Description |
|------|-------------|
| `beacon_list_monitors` | List all monitors with status |
| `beacon_check_status` | Get detailed monitor status |
| `beacon_create_monitor` | Create new monitor |
| `beacon_get_uptime` | Get uptime statistics |
| `beacon_list_incidents` | List incidents/outages |

### Integration Points

| Product | Integration |
|---------|-------------|
| **Signal** | Alerts on status changes |
| **Synapse** | Deploy Agent checks uptime after deploy |
| **Reflex** | Correlate errors with outages |

---

*Beacon = Always watching! 🔦*
