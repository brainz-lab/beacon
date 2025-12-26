class IncidentManager
  def initialize(monitor)
    @monitor = monitor
  end

  def create_incident(severity: "major", title: nil)
    incident = @monitor.incidents.create!(
      title: title || "#{@monitor.name} is experiencing issues",
      status: "investigating",
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

    notify_via_signal(incident, event: "resolved")
    notify_status_page_subscribers(incident, event: "resolved")
  end

  def update_incident(incident, status:, message:, user: "system")
    incident.add_update(status, message, user: user)

    notify_via_signal(incident, event: "updated")
    notify_status_page_subscribers(incident, event: "updated")
  end

  private

  def notify_via_signal(incident, event: "created")
    SignalClient.trigger_alert(
      source: "beacon",
      title: incident.title,
      severity: incident.severity,
      data: {
        monitor_id: @monitor.id,
        monitor_name: @monitor.name,
        incident_id: incident.id,
        event: event,
        status: incident.status
      }
    )
  rescue => e
    Rails.logger.error "[IncidentManager] Failed to notify Signal: #{e.message}"
  end

  def notify_status_page_subscribers(incident, event: "created")
    @monitor.status_pages.each do |status_page|
      status_page.subscriptions.confirmed.find_each do |subscription|
        next unless subscription.should_notify?(incident.severity)

        IncidentNotificationJob.perform_later(
          subscription.id,
          incident.id,
          event
        )
      end
    end
  end
end
