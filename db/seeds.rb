# frozen_string_literal: true

# Seeds for Beacon - Uptime Monitoring Service
# Run with: bin/rails db:seed

puts "Seeding Beacon..."

# Clear existing data in correct order (respecting foreign keys)
puts "Clearing existing data..."
CheckResult.delete_all
IncidentUpdate.delete_all
Incident.delete_all
AlertRule.delete_all
ActiveRecord::Base.connection.execute("DELETE FROM ssl_certificates")
StatusPageMonitor.delete_all
StatusSubscription.delete_all
StatusPage.delete_all
MaintenanceWindow.delete_all
UptimeMonitor.delete_all
Project.delete_all

# =============================================================================
# PROJECT
# =============================================================================
puts "Creating project..."
project = Project.create!(
  platform_project_id: "99963e9e-705e-4aad-9380-af5495b09c98",
  api_key: "bcn_api_#{SecureRandom.hex(16)}",
  ingest_key: "bcn_ingest_#{SecureRandom.hex(16)}",
  name: "Acme Corp Production",
  settings: {
    default_interval: 60,
    default_timeout: 30,
    notification_email: "ops@acme.example.com",
    slack_webhook: "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXX"
  }
)
puts "  Created project: #{project.name}"

# =============================================================================
# MONITORS
# =============================================================================
puts "Creating monitors..."

# HTTP Monitors
api_monitor = UptimeMonitor.create!(
  project: project,
  name: "Production API",
  monitor_type: "http",
  url: "https://api.acme.example.com/health",
  http_method: "GET",
  expected_status: 200,
  expected_body: "ok",
  interval_seconds: 60,
  timeout_seconds: 30,
  regions: %w[nyc london singapore sydney],
  follow_redirects: true,
  verify_ssl: true,
  headers: { "Accept" => "application/json" },
  status: "up",
  enabled: true,
  paused: false,
  last_check_at: 1.minute.ago,
  last_up_at: 1.minute.ago,
  consecutive_successes: 10
)
puts "  Created monitor: #{api_monitor.name}"

website_monitor = UptimeMonitor.create!(
  project: project,
  name: "Marketing Website",
  monitor_type: "http",
  url: "https://www.acme.example.com",
  http_method: "GET",
  expected_status: 200,
  interval_seconds: 60,
  timeout_seconds: 30,
  regions: %w[nyc london],
  follow_redirects: true,
  verify_ssl: true,
  status: "up",
  enabled: true,
  last_check_at: 2.minutes.ago,
  last_up_at: 2.minutes.ago,
  consecutive_successes: 50
)
puts "  Created monitor: #{website_monitor.name}"

dashboard_monitor = UptimeMonitor.create!(
  project: project,
  name: "Customer Dashboard",
  monitor_type: "http",
  url: "https://dashboard.acme.example.com/health",
  http_method: "GET",
  expected_status: 200,
  interval_seconds: 60,
  timeout_seconds: 30,
  regions: %w[nyc london singapore],
  status: "up",
  enabled: true,
  last_check_at: 1.minute.ago,
  last_up_at: 1.minute.ago,
  consecutive_successes: 25
)
puts "  Created monitor: #{dashboard_monitor.name}"

# Degraded monitor (slow responses)
search_monitor = UptimeMonitor.create!(
  project: project,
  name: "Search Service",
  monitor_type: "http",
  url: "https://search.acme.example.com/health",
  http_method: "GET",
  expected_status: 200,
  interval_seconds: 60,
  timeout_seconds: 30,
  regions: %w[nyc london],
  status: "degraded",
  enabled: true,
  last_check_at: 1.minute.ago,
  last_up_at: 1.minute.ago,
  consecutive_successes: 5
)
puts "  Created monitor: #{search_monitor.name} (degraded)"

# Down monitor
payments_monitor = UptimeMonitor.create!(
  project: project,
  name: "Payment Gateway",
  monitor_type: "http",
  url: "https://payments.acme.example.com/health",
  http_method: "GET",
  expected_status: 200,
  interval_seconds: 30,
  timeout_seconds: 15,
  regions: %w[nyc london singapore sydney],
  status: "down",
  enabled: true,
  last_check_at: 30.seconds.ago,
  last_down_at: 30.seconds.ago,
  consecutive_failures: 5
)
puts "  Created monitor: #{payments_monitor.name} (down)"

# TCP Monitor
database_monitor = UptimeMonitor.create!(
  project: project,
  name: "PostgreSQL Primary",
  monitor_type: "tcp",
  host: "db-primary.acme.internal",
  port: 5432,
  interval_seconds: 60,
  timeout_seconds: 10,
  regions: %w[nyc],
  status: "up",
  enabled: true,
  last_check_at: 1.minute.ago,
  last_up_at: 1.minute.ago,
  consecutive_successes: 100
)
puts "  Created monitor: #{database_monitor.name}"

redis_monitor = UptimeMonitor.create!(
  project: project,
  name: "Redis Cache",
  monitor_type: "tcp",
  host: "redis.acme.internal",
  port: 6379,
  interval_seconds: 60,
  timeout_seconds: 10,
  regions: %w[nyc],
  status: "up",
  enabled: true,
  last_check_at: 1.minute.ago,
  last_up_at: 1.minute.ago,
  consecutive_successes: 100
)
puts "  Created monitor: #{redis_monitor.name}"

# DNS Monitor
dns_monitor = UptimeMonitor.create!(
  project: project,
  name: "DNS Resolution",
  monitor_type: "dns",
  host: "acme.example.com",
  interval_seconds: 300,
  timeout_seconds: 10,
  regions: %w[nyc london singapore sydney],
  status: "up",
  enabled: true,
  last_check_at: 5.minutes.ago,
  last_up_at: 5.minutes.ago,
  consecutive_successes: 200
)
puts "  Created monitor: #{dns_monitor.name}"

# SSL Monitor
ssl_monitor = UptimeMonitor.create!(
  project: project,
  name: "SSL Certificate - API",
  monitor_type: "ssl",
  url: "https://api.acme.example.com",
  interval_seconds: 3600,
  timeout_seconds: 30,
  regions: %w[nyc],
  verify_ssl: true,
  ssl_expiry_warn_days: 30,
  ssl_expiry_at: 45.days.from_now,
  status: "up",
  enabled: true,
  last_check_at: 1.hour.ago,
  last_up_at: 1.hour.ago,
  consecutive_successes: 30
)
puts "  Created monitor: #{ssl_monitor.name}"

# SSL Monitor - expiring soon
ssl_expiring_monitor = UptimeMonitor.create!(
  project: project,
  name: "SSL Certificate - Legacy",
  monitor_type: "ssl",
  url: "https://legacy.acme.example.com",
  interval_seconds: 3600,
  timeout_seconds: 30,
  regions: %w[nyc],
  verify_ssl: true,
  ssl_expiry_warn_days: 30,
  ssl_expiry_at: 10.days.from_now,
  status: "up",
  enabled: true,
  last_check_at: 1.hour.ago,
  last_up_at: 1.hour.ago,
  consecutive_successes: 30
)
puts "  Created monitor: #{ssl_expiring_monitor.name} (expiring soon)"

# Ping Monitor
ping_monitor = UptimeMonitor.create!(
  project: project,
  name: "CDN Edge Node",
  monitor_type: "ping",
  host: "edge-nyc.acme.example.com",
  interval_seconds: 60,
  timeout_seconds: 10,
  regions: %w[nyc],
  status: "up",
  enabled: true,
  last_check_at: 1.minute.ago,
  last_up_at: 1.minute.ago,
  consecutive_successes: 500
)
puts "  Created monitor: #{ping_monitor.name}"

# Paused monitor
paused_monitor = UptimeMonitor.create!(
  project: project,
  name: "Staging API",
  monitor_type: "http",
  url: "https://staging-api.acme.example.com/health",
  http_method: "GET",
  expected_status: 200,
  interval_seconds: 60,
  timeout_seconds: 30,
  regions: %w[nyc],
  status: "unknown",
  enabled: true,
  paused: true
)
puts "  Created monitor: #{paused_monitor.name} (paused)"

all_monitors = [
  api_monitor, website_monitor, dashboard_monitor, search_monitor,
  payments_monitor, database_monitor, redis_monitor, dns_monitor,
  ssl_monitor, ssl_expiring_monitor, ping_monitor, paused_monitor
]

# =============================================================================
# CHECK RESULTS (Time-series data)
# =============================================================================
puts "Creating check results..."

regions = %w[nyc london singapore sydney]

# Helper to generate realistic timing
def generate_timing(base_response_time, variance: 50)
  dns_time = rand(5..30)
  connect_time = rand(10..50)
  tls_time = rand(20..80)
  ttfb = rand(50..150)
  total = base_response_time + rand(-variance..variance)

  {
    dns_time_ms: dns_time,
    connect_time_ms: connect_time,
    tls_time_ms: tls_time,
    ttfb_ms: ttfb,
    response_time_ms: [ total, 50 ].max
  }
end

# Generate check results for the past 7 days
active_monitors = all_monitors.reject { |m| m.paused? || m.monitor_type == "ssl" }

active_monitors.each do |monitor|
  check_count = 0
  monitor_regions = monitor.regions & regions

  # Generate checks for the past 2 days (faster seeding)
  (2.days.ago.to_i..Time.current.to_i).step(monitor.interval_seconds) do |timestamp|
    time = Time.at(timestamp)

    monitor_regions.each do |region|
      # 98% uptime for most monitors, lower for degraded/down
      success_rate = case monitor.status
      when "up" then 0.995
      when "degraded" then 0.85
      when "down" then 0.3
      else 0.95
      end

      is_success = rand < success_rate

      if is_success
        base_response = case monitor.status
        when "degraded" then rand(800..2000)
        else rand(100..300)
        end
        timing = generate_timing(base_response)

        CheckResult.create!(
          monitor_id: monitor.id,
          checked_at: time,
          region: region,
          status: "up",
          response_time_ms: timing[:response_time_ms],
          dns_time_ms: timing[:dns_time_ms],
          connect_time_ms: timing[:connect_time_ms],
          tls_time_ms: monitor.monitor_type == "http" ? timing[:tls_time_ms] : nil,
          ttfb_ms: monitor.monitor_type == "http" ? timing[:ttfb_ms] : nil,
          status_code: monitor.monitor_type == "http" ? 200 : nil,
          response_size_bytes: monitor.monitor_type == "http" ? rand(500..5000) : nil,
          resolved_ip: "10.0.#{rand(1..255)}.#{rand(1..255)}"
        )
      else
        error_types = %w[timeout dns_error connection_refused]
        error_type = error_types.sample
        error_messages = {
          "timeout" => "Request timed out after #{monitor.timeout_seconds}s",
          "dns_error" => "DNS resolution failed for #{monitor.host || URI.parse(monitor.url).host}",
          "connection_refused" => "Connection refused by remote host"
        }

        CheckResult.create!(
          monitor_id: monitor.id,
          checked_at: time,
          region: region,
          status: "down",
          response_time_ms: nil,
          error_type: error_type,
          error_message: error_messages[error_type]
        )
      end

      check_count += 1
    end
  end

  puts "  Created #{check_count} check results for #{monitor.name}"
end

# =============================================================================
# SSL CERTIFICATES
# =============================================================================
puts "Creating SSL certificates..."

# Use insert_all to bypass the valid? attribute conflict
now = Time.current
SSLCertificate.insert_all!([
  {
    id: SecureRandom.uuid,
    monitor_id: ssl_monitor.id,
    domain: "api.acme.example.com",
    issuer: "CN=R3,O=Let's Encrypt,C=US",
    subject: "CN=api.acme.example.com",
    serial_number: SecureRandom.hex(18).upcase,
    issued_at: 45.days.ago,
    expires_at: 45.days.from_now,
    valid: true,
    fingerprint_sha256: SecureRandom.hex(32).upcase.scan(/.{2}/).join(":"),
    public_key_algorithm: "RSA",
    public_key_bits: 2048,
    last_checked_at: 1.hour.ago,
    created_at: now,
    updated_at: now
  },
  {
    id: SecureRandom.uuid,
    monitor_id: ssl_expiring_monitor.id,
    domain: "legacy.acme.example.com",
    issuer: "CN=DigiCert SHA2 Extended Validation Server CA,OU=www.digicert.com,O=DigiCert Inc,C=US",
    subject: "CN=legacy.acme.example.com,O=Acme Corp,L=San Francisco,ST=California,C=US",
    serial_number: SecureRandom.hex(18).upcase,
    issued_at: 355.days.ago,
    expires_at: 10.days.from_now,
    valid: true,
    fingerprint_sha256: SecureRandom.hex(32).upcase.scan(/.{2}/).join(":"),
    public_key_algorithm: "ECDSA",
    public_key_bits: 256,
    last_checked_at: 1.hour.ago,
    created_at: now,
    updated_at: now
  }
])
puts "  Created SSL certificate for api.acme.example.com"
puts "  Created SSL certificate for legacy.acme.example.com (expiring soon)"

# =============================================================================
# INCIDENTS
# =============================================================================
puts "Creating incidents..."

# Current active incident for payments monitor
active_incident = Incident.create!(
  uptime_monitor: payments_monitor,
  title: "Payment Gateway Outage",
  status: "investigating",
  severity: "critical",
  started_at: 15.minutes.ago,
  affected_regions: %w[nyc london singapore sydney],
  notified: true,
  notified_at: 14.minutes.ago
)

# Delete auto-created update and create custom ones
active_incident.updates.delete_all

IncidentUpdate.create!(
  incident: active_incident,
  status: "investigating",
  message: "We are investigating connectivity issues with our payment gateway provider.",
  created_by: "system",
  created_at: 15.minutes.ago
)

IncidentUpdate.create!(
  incident: active_incident,
  status: "investigating",
  message: "Our team has identified elevated error rates on the payment processing endpoint. We are working with our provider to resolve this issue.",
  created_by: "Sarah Chen",
  created_at: 10.minutes.ago
)
puts "  Created active incident: #{active_incident.title}"

# Resolved incident from last week
resolved_incident_1 = Incident.create!(
  uptime_monitor: api_monitor,
  title: "API Latency Degradation",
  status: "resolved",
  severity: "major",
  started_at: 3.days.ago,
  identified_at: 3.days.ago + 10.minutes,
  resolved_at: 3.days.ago + 45.minutes,
  duration_seconds: 2700,
  affected_regions: %w[nyc london],
  uptime_impact: 0.15,
  root_cause: "Database connection pool exhaustion due to long-running queries",
  resolution_notes: "Optimized slow queries and increased connection pool size",
  notified: true,
  notified_at: 3.days.ago
)

resolved_incident_1.updates.delete_all

IncidentUpdate.create!(
  incident: resolved_incident_1,
  status: "investigating",
  message: "We are investigating reports of slow API response times.",
  created_by: "system",
  created_at: 3.days.ago
)

IncidentUpdate.create!(
  incident: resolved_incident_1,
  status: "identified",
  message: "We have identified the root cause as database connection pool exhaustion. Our team is implementing a fix.",
  created_by: "Alex Kim",
  created_at: 3.days.ago + 10.minutes
)

IncidentUpdate.create!(
  incident: resolved_incident_1,
  status: "monitoring",
  message: "A fix has been deployed. We are monitoring the situation.",
  created_by: "Alex Kim",
  created_at: 3.days.ago + 35.minutes
)

IncidentUpdate.create!(
  incident: resolved_incident_1,
  status: "resolved",
  message: "The issue has been resolved. API response times have returned to normal. We have optimized slow queries and increased the database connection pool size to prevent future occurrences.",
  created_by: "Alex Kim",
  created_at: 3.days.ago + 45.minutes
)
puts "  Created resolved incident: #{resolved_incident_1.title}"

# Another resolved incident from 2 weeks ago
resolved_incident_2 = Incident.create!(
  uptime_monitor: website_monitor,
  title: "Website Unavailable",
  status: "resolved",
  severity: "critical",
  started_at: 14.days.ago,
  identified_at: 14.days.ago + 5.minutes,
  resolved_at: 14.days.ago + 20.minutes,
  duration_seconds: 1200,
  affected_regions: %w[nyc london],
  uptime_impact: 0.5,
  root_cause: "CDN configuration error during deployment",
  resolution_notes: "Reverted CDN configuration and added validation to deployment pipeline",
  notified: true,
  notified_at: 14.days.ago
)

resolved_incident_2.updates.delete_all

IncidentUpdate.create!(
  incident: resolved_incident_2,
  status: "investigating",
  message: "We are investigating reports of our website being unavailable.",
  created_by: "system",
  created_at: 14.days.ago
)

IncidentUpdate.create!(
  incident: resolved_incident_2,
  status: "identified",
  message: "A CDN configuration error has been identified. Rolling back the recent deployment.",
  created_by: "DevOps Team",
  created_at: 14.days.ago + 5.minutes
)

IncidentUpdate.create!(
  incident: resolved_incident_2,
  status: "resolved",
  message: "The website is back online. The CDN configuration has been reverted and we are adding validation checks to prevent this in the future.",
  created_by: "DevOps Team",
  created_at: 14.days.ago + 20.minutes
)
puts "  Created resolved incident: #{resolved_incident_2.title}"

# Minor incident
resolved_incident_3 = Incident.create!(
  uptime_monitor: search_monitor,
  title: "Search Service Slow Response",
  status: "resolved",
  severity: "minor",
  started_at: 7.days.ago,
  identified_at: 7.days.ago + 15.minutes,
  resolved_at: 7.days.ago + 1.hour,
  duration_seconds: 3600,
  affected_regions: %w[nyc],
  uptime_impact: 0.05,
  root_cause: "Index rebuild in progress",
  resolution_notes: "Index rebuild completed successfully",
  notified: true,
  notified_at: 7.days.ago
)

resolved_incident_3.updates.delete_all

IncidentUpdate.create!(
  incident: resolved_incident_3,
  status: "investigating",
  message: "Search queries are taking longer than usual. We are investigating.",
  created_by: "system",
  created_at: 7.days.ago
)

IncidentUpdate.create!(
  incident: resolved_incident_3,
  status: "identified",
  message: "A scheduled index rebuild is in progress which is causing slower search responses. This is expected to complete within the hour.",
  created_by: "Search Team",
  created_at: 7.days.ago + 15.minutes
)

IncidentUpdate.create!(
  incident: resolved_incident_3,
  status: "resolved",
  message: "Index rebuild has completed. Search performance has returned to normal.",
  created_by: "Search Team",
  created_at: 7.days.ago + 1.hour
)
puts "  Created resolved incident: #{resolved_incident_3.title}"

# =============================================================================
# STATUS PAGE
# =============================================================================
puts "Creating status page..."

status_page = StatusPage.create!(
  project: project,
  name: "Acme Status",
  slug: "acme",
  custom_domain: nil,
  logo_url: nil,
  favicon_url: nil,
  primary_color: "#2563EB",
  company_name: "Acme Corp",
  company_url: "https://www.acme.example.com",
  description: "Real-time status and incident updates for Acme services",
  public: true,
  show_uptime: true,
  show_response_time: true,
  show_incidents: true,
  uptime_days_shown: 90,
  allow_subscriptions: true,
  subscription_channels: %w[email webhook],
  current_status: "partial_outage"
)
puts "  Created status page: #{status_page.name}"

# Add monitors to status page
StatusPageMonitor.create!(
  status_page: status_page,
  monitor_id: api_monitor.id,
  display_name: "API",
  group_name: "Core Services",
  position: 1,
  visible: true
)

StatusPageMonitor.create!(
  status_page: status_page,
  monitor_id: website_monitor.id,
  display_name: "Website",
  group_name: "Core Services",
  position: 2,
  visible: true
)

StatusPageMonitor.create!(
  status_page: status_page,
  monitor_id: dashboard_monitor.id,
  display_name: "Dashboard",
  group_name: "Core Services",
  position: 3,
  visible: true
)

StatusPageMonitor.create!(
  status_page: status_page,
  monitor_id: payments_monitor.id,
  display_name: "Payments",
  group_name: "Core Services",
  position: 4,
  visible: true
)

StatusPageMonitor.create!(
  status_page: status_page,
  monitor_id: search_monitor.id,
  display_name: "Search",
  group_name: "Features",
  position: 5,
  visible: true
)

StatusPageMonitor.create!(
  status_page: status_page,
  monitor_id: database_monitor.id,
  display_name: "Database",
  group_name: "Infrastructure",
  position: 6,
  visible: true
)

StatusPageMonitor.create!(
  status_page: status_page,
  monitor_id: redis_monitor.id,
  display_name: "Cache",
  group_name: "Infrastructure",
  position: 7,
  visible: true
)
puts "  Added 7 monitors to status page"

# =============================================================================
# STATUS SUBSCRIPTIONS
# =============================================================================
puts "Creating status subscriptions..."

StatusSubscription.create!(
  status_page: status_page,
  email: "ops-team@acme.example.com",
  channel: "email",
  confirmed: true,
  confirmed_at: 30.days.ago,
  notify_incidents: true,
  notify_maintenance: true,
  severity_filter: %w[minor major critical]
)

StatusSubscription.create!(
  status_page: status_page,
  email: "engineering@acme.example.com",
  channel: "email",
  confirmed: true,
  confirmed_at: 20.days.ago,
  notify_incidents: true,
  notify_maintenance: true,
  severity_filter: %w[major critical]
)

StatusSubscription.create!(
  status_page: status_page,
  email: "cto@acme.example.com",
  channel: "email",
  confirmed: true,
  confirmed_at: 15.days.ago,
  notify_incidents: true,
  notify_maintenance: false,
  severity_filter: %w[critical]
)

StatusSubscription.create!(
  status_page: status_page,
  email: "pending-user@example.com",
  channel: "email",
  confirmed: false,
  confirmation_token: SecureRandom.urlsafe_base64(32),
  notify_incidents: true,
  notify_maintenance: true,
  severity_filter: %w[minor major critical]
)

StatusSubscription.create!(
  status_page: status_page,
  webhook_url: "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXX",
  channel: "webhook",
  confirmed: true,
  confirmed_at: 25.days.ago,
  notify_incidents: true,
  notify_maintenance: true,
  severity_filter: %w[major critical]
)
puts "  Created 5 status subscriptions"

# =============================================================================
# MAINTENANCE WINDOWS
# =============================================================================
puts "Creating maintenance windows..."

# Upcoming maintenance
MaintenanceWindow.create!(
  project: project,
  title: "Database Upgrade",
  description: "Upgrading PostgreSQL to the latest version. Expected downtime: 15 minutes.",
  starts_at: 3.days.from_now.change(hour: 4, min: 0),
  ends_at: 3.days.from_now.change(hour: 5, min: 0),
  timezone: "America/New_York",
  monitor_ids: [ database_monitor.id ],
  affects_all_monitors: false,
  status: "scheduled",
  notify_subscribers: true,
  notify_before_minutes: 60,
  notified: false
)
puts "  Created upcoming maintenance: Database Upgrade"

# Completed maintenance
MaintenanceWindow.create!(
  project: project,
  title: "SSL Certificate Renewal",
  description: "Renewing SSL certificates for all services.",
  starts_at: 5.days.ago.change(hour: 3, min: 0),
  ends_at: 5.days.ago.change(hour: 4, min: 0),
  timezone: "America/New_York",
  monitor_ids: [ ssl_monitor.id, ssl_expiring_monitor.id ],
  affects_all_monitors: false,
  status: "completed",
  notify_subscribers: true,
  notify_before_minutes: 60,
  notified: true
)
puts "  Created completed maintenance: SSL Certificate Renewal"

# Major upcoming maintenance
MaintenanceWindow.create!(
  project: project,
  title: "Infrastructure Migration",
  description: "Migrating to new data center. All services will experience brief interruptions.",
  starts_at: 14.days.from_now.change(hour: 2, min: 0),
  ends_at: 14.days.from_now.change(hour: 6, min: 0),
  timezone: "UTC",
  monitor_ids: [],
  affects_all_monitors: true,
  status: "scheduled",
  notify_subscribers: true,
  notify_before_minutes: 1440, # 24 hours
  notified: false
)
puts "  Created major maintenance: Infrastructure Migration"

# =============================================================================
# ALERT RULES
# =============================================================================
puts "Creating alert rules..."

# Status change alerts for critical monitors
[ api_monitor, payments_monitor, database_monitor ].each do |m|
  AlertRule.create!(
    monitor_id: m.id,
    name: "#{m.name} Down Alert",
    enabled: true,
    condition_type: "status_change",
    condition_config: { "from" => "up", "to" => "down" }
  )
end
puts "  Created 3 status change alerts"

# Response time alerts
AlertRule.create!(
  monitor_id: api_monitor.id,
  name: "API Slow Response Alert",
  enabled: true,
  condition_type: "response_time",
  condition_config: { "operator" => "gt", "value" => 1000 }
)

AlertRule.create!(
  monitor_id: search_monitor.id,
  name: "Search Performance Alert",
  enabled: true,
  condition_type: "response_time",
  condition_config: { "operator" => "gt", "value" => 2000 }
)
puts "  Created 2 response time alerts"

# SSL expiry alerts
AlertRule.create!(
  monitor_id: ssl_monitor.id,
  name: "SSL Expiry Warning (30 days)",
  enabled: true,
  condition_type: "ssl_expiry",
  condition_config: { "days_before" => 30 }
)

AlertRule.create!(
  monitor_id: ssl_monitor.id,
  name: "SSL Expiry Critical (7 days)",
  enabled: true,
  condition_type: "ssl_expiry",
  condition_config: { "days_before" => 7 }
)

AlertRule.create!(
  monitor_id: ssl_expiring_monitor.id,
  name: "Legacy SSL Expiry Warning",
  enabled: true,
  condition_type: "ssl_expiry",
  condition_config: { "days_before" => 14 }
)
puts "  Created 3 SSL expiry alerts"

# Consecutive failures alert
AlertRule.create!(
  monitor_id: payments_monitor.id,
  name: "Payment Gateway Repeated Failures",
  enabled: true,
  condition_type: "consecutive_failures",
  condition_config: { "count" => 3 }
)
puts "  Created 1 consecutive failures alert"

# =============================================================================
# SUMMARY
# =============================================================================
puts ""
puts "=" * 60
puts "Beacon seeding complete!"
puts "=" * 60
puts ""
puts "Created:"
puts "  - 1 project (#{project.name})"
puts "  - #{all_monitors.count} monitors (#{all_monitors.count { |m| m.status == 'up' }} up, #{all_monitors.count { |m| m.status == 'degraded' }} degraded, #{all_monitors.count { |m| m.status == 'down' }} down, #{all_monitors.count(&:paused?)} paused)"
puts "  - #{CheckResult.count} check results"
puts "  - #{ActiveRecord::Base.connection.select_value('SELECT COUNT(*) FROM ssl_certificates')} SSL certificates"
puts "  - #{Incident.count} incidents (#{Incident.active.count} active, #{Incident.resolved.count} resolved)"
puts "  - #{IncidentUpdate.count} incident updates"
puts "  - 1 status page with #{StatusPageMonitor.count} monitors"
puts "  - #{StatusSubscription.count} status subscriptions"
puts "  - #{MaintenanceWindow.count} maintenance windows"
puts "  - #{AlertRule.count} alert rules"
puts ""
puts "Dashboard: http://beacon.localhost/dashboard/projects/#{project.platform_project_id}"
puts ""
