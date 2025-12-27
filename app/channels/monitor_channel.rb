class MonitorChannel < ApplicationCable::Channel
  def subscribed
    @monitor = UptimeMonitor.find(params[:id])

    # Verify monitor belongs to current project
    if @monitor.project_id == current_project_id
      stream_for @monitor
    else
      reject
    end
  end

  def unsubscribed
    stop_all_streams
  end

  # Broadcast a check result to all subscribers
  def self.broadcast_check(monitor, check_result)
    broadcast_to monitor, {
      type: "check_result",
      data: {
        id: check_result.id,
        status: check_result.status,
        response_time: check_result.response_time,
        status_code: check_result.status_code,
        checked_at: check_result.checked_at,
        region: check_result.region,
        error_message: check_result.error_message
      }
    }
  end

  # Broadcast status change
  def self.broadcast_status_change(monitor, old_status, new_status)
    broadcast_to monitor, {
      type: "status_change",
      data: {
        old_status: old_status,
        new_status: new_status,
        changed_at: Time.current
      }
    }
  end

  # Broadcast incident creation
  def self.broadcast_incident(monitor, incident)
    broadcast_to monitor, {
      type: "incident_created",
      data: {
        id: incident.id,
        title: incident.title,
        severity: incident.severity,
        started_at: incident.started_at
      }
    }
  end
end
