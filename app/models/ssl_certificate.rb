class SslCertificate < ApplicationRecord
  belongs_to :uptime_monitor, foreign_key: :monitor_id

  validates :domain, presence: true

  scope :expiring_soon, ->(days = 30) { where("expires_at < ?", days.days.from_now) }
  scope :expired, -> { where("expires_at < ?", Time.current) }
  scope :valid_certs, -> { where(valid: true) }

  # Days until expiry
  def days_until_expiry
    return nil unless expires_at
    ((expires_at - Time.current) / 1.day).to_i
  end

  # Is the certificate expiring soon?
  def expiring_soon?(days = 30)
    return false unless expires_at
    expires_at < days.days.from_now
  end

  # Is the certificate expired?
  def expired?
    return false unless expires_at
    expires_at < Time.current
  end

  # Certificate status for display
  def status
    if !valid
      "invalid"
    elsif expired?
      "expired"
    elsif expiring_soon?(7)
      "critical"
    elsif expiring_soon?(30)
      "warning"
    else
      "valid"
    end
  end

  # Human-readable issuer name
  def issuer_name
    return nil unless issuer
    # Extract CN from issuer string
    issuer.match(/CN=([^,]+)/)&.[](1) || issuer
  end
end
