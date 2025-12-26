class MaintenanceWindow < ApplicationRecord
  belongs_to :project

  validates :title, presence: true
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validate :ends_after_starts

  scope :upcoming, -> { where("starts_at > ?", Time.current).order(:starts_at) }
  scope :active, -> { where("starts_at <= ? AND ends_at > ?", Time.current, Time.current) }
  scope :past, -> { where("ends_at <= ?", Time.current).order(starts_at: :desc) }
  scope :scheduled, -> { where(status: "scheduled") }
  scope :in_progress, -> { where(status: "in_progress") }

  STATUSES = %w[scheduled in_progress completed cancelled].freeze

  # Get affected monitors
  def affected_monitors
    if affects_all_monitors
      project.monitors
    else
      project.monitors.where(id: monitor_ids)
    end
  end

  # Is the maintenance currently active?
  def active?
    Time.current.between?(starts_at, ends_at)
  end

  # Is the maintenance upcoming?
  def upcoming?
    starts_at > Time.current
  end

  # Is the maintenance completed?
  def completed?
    ends_at <= Time.current || status == "completed"
  end

  # Duration in seconds
  def duration
    ends_at - starts_at
  end

  # Human-readable duration
  def duration_humanized
    seconds = duration.to_i
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60

    if hours > 0
      "#{hours}h #{minutes}m"
    else
      "#{minutes}m"
    end
  end

  # Start the maintenance
  def start!
    update!(status: "in_progress")
  end

  # Complete the maintenance
  def complete!
    update!(status: "completed")
  end

  # Cancel the maintenance
  def cancel!
    update!(status: "cancelled")
  end

  private

  def ends_after_starts
    if starts_at.present? && ends_at.present? && ends_at <= starts_at
      errors.add(:ends_at, "must be after start time")
    end
  end
end
