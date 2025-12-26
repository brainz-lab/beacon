class StatusSubscription < ApplicationRecord
  belongs_to :status_page

  validates :channel, presence: true, inclusion: { in: %w[email sms webhook] }
  validates :email, presence: true, if: -> { channel == "email" }
  validates :phone, presence: true, if: -> { channel == "sms" }
  validates :webhook_url, presence: true, if: -> { channel == "webhook" }

  before_create :generate_confirmation_token

  scope :confirmed, -> { where(confirmed: true) }
  scope :pending, -> { where(confirmed: false) }
  scope :by_channel, ->(channel) { where(channel: channel) }

  # Confirm the subscription
  def confirm!
    update!(confirmed: true, confirmed_at: Time.current, confirmation_token: nil)
  end

  # Check if subscription should receive notification for severity
  def should_notify?(severity)
    severity_filter.include?(severity)
  end

  # Notification target (email, phone, or webhook URL)
  def target
    case channel
    when "email" then email
    when "sms" then phone
    when "webhook" then webhook_url
    end
  end

  private

  def generate_confirmation_token
    self.confirmation_token = SecureRandom.urlsafe_base64(32)
  end
end
