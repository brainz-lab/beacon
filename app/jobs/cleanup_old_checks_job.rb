class CleanupOldChecksJob < ApplicationJob
  queue_as :default

  # Default retention period
  RETENTION_DAYS = 90

  def perform(retention_days: RETENTION_DAYS)
    Rails.logger.info "[CleanupOldChecksJob] Starting cleanup (retention: #{retention_days} days)..."

    cutoff_date = retention_days.days.ago

    # Delete old check results
    # Note: TimescaleDB may have its own retention policy, but this is a backup
    deleted_count = CheckResult.where("checked_at < ?", cutoff_date).delete_all

    Rails.logger.info "[CleanupOldChecksJob] Deleted #{deleted_count} old check results"

    # Clean up old resolved incidents (keep for longer - 1 year)
    incident_cutoff = 1.year.ago
    old_incidents = Incident.resolved.where("resolved_at < ?", incident_cutoff)
    incidents_deleted = old_incidents.destroy_all.count

    Rails.logger.info "[CleanupOldChecksJob] Deleted #{incidents_deleted} old resolved incidents"

    # Clean up expired confirmation tokens
    expired_subscriptions = StatusSubscription
      .where(confirmed: false)
      .where("created_at < ?", 7.days.ago)
    subscriptions_deleted = expired_subscriptions.delete_all

    Rails.logger.info "[CleanupOldChecksJob] Deleted #{subscriptions_deleted} unconfirmed subscriptions"

    {
      check_results_deleted: deleted_count,
      incidents_deleted: incidents_deleted,
      subscriptions_deleted: subscriptions_deleted
    }
  end
end
