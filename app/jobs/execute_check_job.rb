class ExecuteCheckJob < ApplicationJob
  queue_as :checks

  def perform(monitor_id, region: nil)
    monitor = UptimeMonitor.find_by(id: monitor_id)
    return unless monitor
    return unless monitor.enabled? && !monitor.paused?

    # Execute the check
    region ||= Beacon.current_region
    monitor.check!(region: region)

    # Schedule next check
    schedule_next_check(monitor)
  rescue => e
    Rails.logger.error "[ExecuteCheckJob] Failed for monitor #{monitor_id}: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    raise
  end

  private

  def schedule_next_check(monitor)
    # Only schedule if still enabled
    return unless monitor.enabled? && !monitor.paused?

    ExecuteCheckJob
      .set(wait: monitor.interval_seconds.seconds)
      .perform_later(monitor.id)
  end
end
