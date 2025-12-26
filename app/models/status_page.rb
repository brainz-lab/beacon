class StatusPage < ApplicationRecord
  belongs_to :project

  has_many :status_page_monitors, dependent: :destroy
  has_many :monitors, through: :status_page_monitors
  has_many :subscriptions, class_name: "StatusSubscription", dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }

  before_validation :generate_slug, if: -> { slug.blank? }

  STATUSES = {
    "operational" => { priority: 0, label: "All Systems Operational", color: "#10B981" },
    "degraded" => { priority: 1, label: "Degraded Performance", color: "#F59E0B" },
    "partial_outage" => { priority: 2, label: "Partial Outage", color: "#F97316" },
    "major_outage" => { priority: 3, label: "Major Outage", color: "#EF4444" }
  }.freeze

  # Calculate overall status from monitors
  def calculate_status
    statuses = monitors.pluck(:status)

    return "operational" if statuses.empty?

    if statuses.all? { |s| s == "up" }
      "operational"
    elsif statuses.all? { |s| s == "down" }
      "major_outage"
    elsif statuses.any? { |s| s == "down" }
      "partial_outage"
    elsif statuses.any? { |s| s == "degraded" }
      "degraded"
    else
      "operational"
    end
  end

  # Update and persist current status
  def update_status!
    update!(current_status: calculate_status)
    broadcast_status
  end

  # Get monitors grouped by category
  def monitors_by_group
    status_page_monitors
      .includes(:monitor)
      .where(visible: true)
      .order(:position)
      .group_by(&:group_name)
  end

  # Get active incidents for all monitors on this page
  def active_incidents
    Incident.active
            .joins(:monitor)
            .where(monitors: { id: monitor_ids })
            .order(started_at: :desc)
  end

  # Get recent resolved incidents
  def recent_incidents(limit: 10)
    Incident.resolved
            .joins(:monitor)
            .where(monitors: { id: monitor_ids })
            .order(started_at: :desc)
            .limit(limit)
  end

  # Calculate overall uptime across all monitors
  def overall_uptime(days: 90)
    uptimes = monitors.map { |m| m.uptime(period: days.days) }
    return 100.0 if uptimes.empty?

    (uptimes.sum / uptimes.size).round(2)
  end

  # Status info for display
  def status_info
    STATUSES[current_status] || STATUSES["operational"]
  end

  # Confirmed subscriptions
  def confirmed_subscriptions
    subscriptions.where(confirmed: true)
  end

  private

  def generate_slug
    self.slug = name.to_s.parameterize
  end

  def broadcast_status
    ActionCable.server.broadcast(
      "status_page_#{id}",
      {
        type: "status_update",
        status: current_status,
        status_info: status_info
      }
    )
  end
end
