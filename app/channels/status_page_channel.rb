class StatusPageChannel < ApplicationCable::Channel
  def subscribed
    @status_page = StatusPage.find_by!(slug: params[:slug])

    # Public status pages can be subscribed to by anyone
    if @status_page.public?
      stream_for @status_page
    else
      reject
    end
  end

  def unsubscribed
    stop_all_streams
  end

  # Broadcast status update to all viewers
  def self.broadcast_status_update(status_page)
    calculator = StatusCalculator.new(status_page)

    broadcast_to status_page, {
      type: "status_update",
      data: {
        status: calculator.overall_status,
        status_info: calculator.status_info,
        components: calculator.component_statuses,
        updated_at: Time.current
      }
    }
  end

  # Broadcast incident created
  def self.broadcast_incident_created(status_page, incident)
    broadcast_to status_page, {
      type: "incident_created",
      data: {
        id: incident.id,
        title: incident.title,
        status: incident.status,
        severity: incident.severity,
        started_at: incident.started_at
      }
    }
  end

  # Broadcast incident update
  def self.broadcast_incident_updated(status_page, incident, update)
    broadcast_to status_page, {
      type: "incident_updated",
      data: {
        incident_id: incident.id,
        update: {
          status: update.status,
          message: update.message,
          created_at: update.created_at
        }
      }
    }
  end

  # Broadcast incident resolved
  def self.broadcast_incident_resolved(status_page, incident)
    broadcast_to status_page, {
      type: "incident_resolved",
      data: {
        id: incident.id,
        title: incident.title,
        resolved_at: incident.resolved_at,
        duration: incident.duration_humanized
      }
    }
  end

  # Broadcast maintenance window
  def self.broadcast_maintenance(status_page, maintenance_window, event_type)
    broadcast_to status_page, {
      type: "maintenance_#{event_type}",
      data: {
        id: maintenance_window.id,
        title: maintenance_window.title,
        starts_at: maintenance_window.starts_at,
        ends_at: maintenance_window.ends_at
      }
    }
  end
end
