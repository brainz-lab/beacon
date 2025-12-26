class MaintenanceWindowJob < ApplicationJob
  queue_as :default

  def perform(action, maintenance_window_id)
    window = MaintenanceWindow.find_by(id: maintenance_window_id)
    return unless window

    case action.to_s
    when "start"
      start_maintenance(window)
    when "end"
      end_maintenance(window)
    when "notify_upcoming"
      notify_upcoming(window)
    end
  end

  private

  def start_maintenance(window)
    return unless window.status == "scheduled"

    window.start!

    # Pause affected monitors
    window.affected_monitors.each do |monitor|
      monitor.update!(paused: true)
    end

    # Notify subscribers
    notify_subscribers(window, "started")

    Rails.logger.info "[MaintenanceWindowJob] Started maintenance: #{window.title}"

    # Schedule end job
    if window.ends_at > Time.current
      wait_time = window.ends_at - Time.current
      MaintenanceWindowJob.set(wait: wait_time).perform_later("end", window.id)
    end
  end

  def end_maintenance(window)
    return unless window.status == "in_progress"

    window.complete!

    # Resume affected monitors
    window.affected_monitors.each do |monitor|
      monitor.update!(paused: false)
      # Trigger immediate check
      ExecuteCheckJob.perform_later(monitor.id)
    end

    # Notify subscribers
    notify_subscribers(window, "completed")

    Rails.logger.info "[MaintenanceWindowJob] Completed maintenance: #{window.title}"
  end

  def notify_upcoming(window)
    return unless window.upcoming? && window.notify_subscribers

    # Find all status pages for the project
    window.project.status_pages.each do |status_page|
      status_page.subscriptions.confirmed.where(notify_maintenance: true).find_each do |subscription|
        # Send notification about upcoming maintenance
        notify_subscriber(subscription, window)
      end
    end

    window.update!(notified: true)
    Rails.logger.info "[MaintenanceWindowJob] Sent upcoming notifications for: #{window.title}"
  end

  def notify_subscribers(window, event)
    window.project.status_pages.each do |status_page|
      status_page.subscriptions.confirmed.where(notify_maintenance: true).find_each do |subscription|
        # Send maintenance update notification
        Rails.logger.info "[MaintenanceWindowJob] Would notify #{subscription.target} about #{event}"
      end
    end
  end

  def notify_subscriber(subscription, window)
    case subscription.channel
    when "email"
      Rails.logger.info "[MaintenanceWindowJob] Would email #{subscription.email} about upcoming maintenance"
    when "webhook"
      send_webhook(subscription, window)
    end
  end

  def send_webhook(subscription, window)
    conn = Faraday.new do |f|
      f.options.timeout = 10
    end

    conn.post(subscription.webhook_url) do |req|
      req.headers["Content-Type"] = "application/json"
      req.body = {
        event: "maintenance_scheduled",
        maintenance: {
          id: window.id,
          title: window.title,
          description: window.description,
          starts_at: window.starts_at.iso8601,
          ends_at: window.ends_at.iso8601
        }
      }.to_json
    end
  rescue => e
    Rails.logger.error "[MaintenanceWindowJob] Webhook failed: #{e.message}"
  end
end
