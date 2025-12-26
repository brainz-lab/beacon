class IncidentNotificationJob < ApplicationJob
  queue_as :notifications

  def perform(subscription_id_or_incident_id, incident_id_or_event = nil, event = nil)
    # Handle both calling conventions:
    # 1. perform(subscription_id, incident_id, event) - for status subscriptions
    # 2. perform(incident_id, event) - for general incident notifications

    if incident_id_or_event.is_a?(String) && %w[created updated resolved].include?(incident_id_or_event)
      # Called with (incident_id, event)
      notify_all_subscribers(subscription_id_or_incident_id, incident_id_or_event)
    else
      # Called with (subscription_id, incident_id, event)
      notify_subscription(subscription_id_or_incident_id, incident_id_or_event, event)
    end
  end

  private

  def notify_all_subscribers(incident_id, event)
    incident = Incident.find(incident_id)
    monitor = incident.monitor

    monitor.status_pages.each do |status_page|
      status_page.subscriptions.confirmed.find_each do |subscription|
        next unless subscription.should_notify?(incident.severity)

        notify_subscription(subscription.id, incident_id, event)
      end
    end
  end

  def notify_subscription(subscription_id, incident_id, event)
    subscription = StatusSubscription.find(subscription_id)
    incident = Incident.find(incident_id)

    case subscription.channel
    when "email"
      send_email(subscription, incident, event)
    when "sms"
      send_sms(subscription, incident, event)
    when "webhook"
      send_webhook(subscription, incident, event)
    end
  rescue => e
    Rails.logger.error "[IncidentNotificationJob] Failed: #{e.message}"
    raise
  end

  def send_email(subscription, incident, event)
    # In production, this would use ActionMailer
    Rails.logger.info "[IncidentNotificationJob] Would send email to #{subscription.email}"
    Rails.logger.info "  Event: #{event}, Incident: #{incident.title}"

    # IncidentMailer.notification(
    #   email: subscription.email,
    #   incident: incident,
    #   event: event
    # ).deliver_now
  end

  def send_sms(subscription, incident, event)
    Rails.logger.info "[IncidentNotificationJob] Would send SMS to #{subscription.phone}"
    Rails.logger.info "  Message: #{build_sms_message(incident, event)}"

    # Twilio::Client.send_sms(
    #   to: subscription.phone,
    #   body: build_sms_message(incident, event)
    # )
  end

  def send_webhook(subscription, incident, event)
    Rails.logger.info "[IncidentNotificationJob] Sending webhook to #{subscription.webhook_url}"

    conn = Faraday.new do |f|
      f.options.timeout = 10
      f.options.open_timeout = 5
    end

    response = conn.post(subscription.webhook_url) do |req|
      req.headers["Content-Type"] = "application/json"
      req.body = build_webhook_payload(incident, event).to_json
    end

    unless response.success?
      Rails.logger.warn "[IncidentNotificationJob] Webhook returned #{response.status}"
    end
  rescue Faraday::Error => e
    Rails.logger.error "[IncidentNotificationJob] Webhook failed: #{e.message}"
  end

  def build_sms_message(incident, event)
    monitor_name = incident.monitor.name

    case event
    when "created"
      "#{incident.severity.upcase}: #{monitor_name} - #{incident.title}"
    when "resolved"
      "RESOLVED: #{monitor_name} is back up"
    else
      "UPDATE: #{monitor_name} - #{incident.status}"
    end
  end

  def build_webhook_payload(incident, event)
    {
      event: event,
      timestamp: Time.current.iso8601,
      incident: {
        id: incident.id,
        title: incident.title,
        status: incident.status,
        severity: incident.severity,
        started_at: incident.started_at.iso8601,
        resolved_at: incident.resolved_at&.iso8601,
        duration_seconds: incident.duration_seconds
      },
      monitor: {
        id: incident.monitor_id,
        name: incident.monitor.name,
        url: incident.monitor.url || incident.monitor.host
      }
    }
  end
end
