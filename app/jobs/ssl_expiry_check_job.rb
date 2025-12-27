class SslExpiryCheckJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "[SslExpiryCheckJob] Checking SSL certificate expiry..."

    # Find monitors with SSL expiry dates
    monitors_with_ssl = UptimeMonitor
      .where(monitor_type: %w[http ssl])
      .where.not(ssl_expiry_at: nil)

    alerts_sent = 0

    monitors_with_ssl.find_each do |monitor|
      days_left = ((monitor.ssl_expiry_at - Time.current) / 1.day).to_i

      next if days_left > 30 # Only alert for certificates expiring within 30 days

      severity = determine_severity(days_left)
      notify_ssl_expiry(monitor, days_left, severity: severity)
      alerts_sent += 1
    end

    Rails.logger.info "[SslExpiryCheckJob] Sent #{alerts_sent} SSL expiry alerts"
  end

  private

  def determine_severity(days_left)
    if days_left <= 0
      "critical"
    elsif days_left <= 7
      "critical"
    elsif days_left <= 14
      "major"
    else
      "minor"
    end
  end

  def notify_ssl_expiry(monitor, days_left, severity:)
    title = if days_left <= 0
              "SSL certificate EXPIRED: #{monitor.name}"
            else
              "SSL certificate expiring soon: #{monitor.name}"
            end

    message = if days_left <= 0
                "Certificate expired on #{monitor.ssl_expiry_at.strftime('%Y-%m-%d')}"
              else
                "Certificate expires in #{days_left} days (#{monitor.ssl_expiry_at.strftime('%Y-%m-%d')})"
              end

    SignalClient.trigger_alert(
      source: "beacon",
      title: title,
      severity: severity,
      data: {
        monitor_id: monitor.id,
        monitor_name: monitor.name,
        monitor_url: monitor.url,
        ssl_expiry_at: monitor.ssl_expiry_at,
        days_left: days_left,
        message: message
      }
    )
  rescue => e
    Rails.logger.error "[SslExpiryCheckJob] Failed to send alert for #{monitor.name}: #{e.message}"
  end
end
