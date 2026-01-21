class NotificationPreference < ApplicationRecord
  belongs_to :user

  WEBHOOK_TYPES = %w[slack discord generic].freeze
  DIGEST_FREQUENCIES = %w[immediate daily weekly].freeze

  validates :webhook_type, inclusion: { in: WEBHOOK_TYPES }, allow_nil: true
  validates :digest_frequency, inclusion: { in: DIGEST_FREQUENCIES }
  validates :webhook_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true

  def should_notify?(notification_type)
    case notification_type
    when Notification::SCAN_COMPLETE
      notify_on_scan_complete?
    when Notification::CRITICAL_VULNERABILITY
      notify_on_critical_vuln?
    when Notification::HIGH_VULNERABILITY
      notify_on_high_vuln?
    else
      true
    end
  end

  def webhook_configured?
    webhook_enabled? && webhook_url.present?
  end

  def slack?
    webhook_type == "slack"
  end

  def discord?
    webhook_type == "discord"
  end
end
