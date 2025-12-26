class IncidentUpdate < ApplicationRecord
  belongs_to :incident

  validates :status, presence: true
  validates :message, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :chronological, -> { order(created_at: :asc) }

  # Was this update created by a human?
  def human_created?
    created_by.present? && created_by != "system"
  end
end
