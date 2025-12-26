class ProjectChannel < ApplicationCable::Channel
  def subscribed
    stream_from "project_#{current_project_id}"
  end

  def unsubscribed
    stop_all_streams
  end

  # Broadcast project-wide updates
  def self.broadcast_to_project(project_id, message)
    ActionCable.server.broadcast("project_#{project_id}", message)
  end

  # Broadcast monitor status update
  def self.broadcast_monitor_status(project_id, monitor)
    broadcast_to_project project_id, {
      type: "monitor_status",
      data: {
        id: monitor.id,
        name: monitor.name,
        status: monitor.status,
        last_check_at: monitor.last_check_at,
        response_time: monitor.last_response_time
      }
    }
  end

  # Broadcast incident update
  def self.broadcast_incident_update(project_id, incident, event_type)
    broadcast_to_project project_id, {
      type: "incident_#{event_type}",
      data: {
        id: incident.id,
        title: incident.title,
        status: incident.status,
        severity: incident.severity,
        monitor: {
          id: incident.monitor_id,
          name: incident.monitor.name
        }
      }
    }
  end

  # Broadcast stats refresh
  def self.broadcast_stats(project_id, stats)
    broadcast_to_project project_id, {
      type: "stats_update",
      data: stats
    }
  end
end
