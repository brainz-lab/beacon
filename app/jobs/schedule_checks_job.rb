class ScheduleChecksJob < ApplicationJob
  queue_as :scheduler

  def perform
    Rails.logger.info "[ScheduleChecksJob] Starting check scheduling..."

    scheduled_count = 0

    UptimeMonitor.enabled.find_each do |monitor|
      # Skip if already has a pending job
      next if check_pending?(monitor)

      # Skip if recently checked
      if monitor.last_check_at.present?
        next_check_at = monitor.last_check_at + monitor.interval_seconds.seconds
        wait_time = [next_check_at - Time.current, 0].max

        if wait_time > 0
          ExecuteCheckJob.set(wait: wait_time).perform_later(monitor.id)
          scheduled_count += 1
          next
        end
      end

      # Run immediately
      ExecuteCheckJob.perform_later(monitor.id)
      scheduled_count += 1
    end

    Rails.logger.info "[ScheduleChecksJob] Scheduled #{scheduled_count} checks"
  end

  private

  def check_pending?(monitor)
    # Check if there's already a pending job for this monitor
    # This is a simple implementation - in production you might want
    # to use a more sophisticated approach with Redis
    false
  end
end
