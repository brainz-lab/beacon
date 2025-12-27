class Incident < ApplicationRecord
  belongs_to :uptime_monitor, foreign_key: :monitor_id

  has_many :updates, class_name: "IncidentUpdate", dependent: :destroy

  validates :title, presence: true
  validates :status, presence: true
  validates :started_at, presence: true

  scope :active, -> { where(status: %w[investigating identified monitoring]) }
  scope :resolved, -> { where(status: "resolved") }
  scope :recent, -> { order(started_at: :desc) }

  after_create :create_initial_update
  after_create :schedule_notification

  STATUSES = %w[investigating identified monitoring resolved].freeze
  SEVERITIES = %w[minor major critical].freeze

  # Resolve the incident
  def resolve!(notes: nil)
    update!(
      status: "resolved",
      resolved_at: Time.current,
      duration_seconds: (Time.current - started_at).to_i,
      resolution_notes: notes
    )

    add_update("resolved", notes || "This incident has been resolved.")
    schedule_resolution_notification
  end

  # Add a status update
  def add_update(new_status, message, user: "system")
    updates.create!(
      status: new_status,
      message: message,
      created_by: user
    )

    update!(status: new_status)
    broadcast_update
  end

  # Duration in seconds
  def duration
    if resolved_at
      resolved_at - started_at
    else
      Time.current - started_at
    end
  end

  # Human-readable duration
  def duration_humanized
    seconds = duration.to_i
    parts = []

    days = seconds / 86400
    hours = (seconds % 86400) / 3600
    minutes = (seconds % 3600) / 60
    secs = seconds % 60

    parts << "#{days}d" if days > 0
    parts << "#{hours}h" if hours > 0
    parts << "#{minutes}m" if minutes > 0
    parts << "#{secs}s" if secs > 0 && days == 0 && hours == 0

    parts.empty? ? "0s" : parts.join(" ")
  end

  # Is the incident active?
  def active?
    !resolved?
  end

  def resolved?
    status == "resolved"
  end

  private

  def create_initial_update
    updates.create!(
      status: "investigating",
      message: "We are investigating issues with #{uptime_monitor.name}.",
      created_by: "system"
    )
  end

  def schedule_notification
    IncidentNotificationJob.perform_later(id, "created")
  end

  def schedule_resolution_notification
    IncidentNotificationJob.perform_later(id, "resolved")
  end

  def broadcast_update
    uptime_monitor.status_pages.each do |status_page|
      ActionCable.server.broadcast(
        "status_page_#{status_page.id}",
        {
          type: "incident_update",
          incident_id: id,
          status: status,
          title: title,
          severity: severity
        }
      )
    end
  end
end
