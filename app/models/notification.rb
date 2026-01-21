class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true

  # Notification types
  SCAN_COMPLETE = "scan_complete".freeze
  CRITICAL_VULNERABILITY = "critical_vulnerability".freeze
  HIGH_VULNERABILITY = "high_vulnerability".freeze
  REPORT_READY = "report_ready".freeze
  MEMBER_ADDED = "member_added".freeze
  MEMBER_REMOVED = "member_removed".freeze

  TYPES = [
    SCAN_COMPLETE,
    CRITICAL_VULNERABILITY,
    HIGH_VULNERABILITY,
    REPORT_READY,
    MEMBER_ADDED,
    MEMBER_REMOVED
  ].freeze

  validates :notification_type, presence: true, inclusion: { in: TYPES }
  validates :title, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(notification_type: type) }

  def read?
    read_at.present?
  end

  def unread?
    read_at.nil?
  end

  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end

  def mark_as_unread!
    update!(read_at: nil) if read?
  end

  def icon_class
    case notification_type
    when SCAN_COMPLETE
      "text-low"
    when CRITICAL_VULNERABILITY
      "text-critical"
    when HIGH_VULNERABILITY
      "text-high"
    when REPORT_READY
      "text-primary"
    when MEMBER_ADDED, MEMBER_REMOVED
      "text-medium"
    else
      "text-text-muted"
    end
  end

  def icon_path
    case notification_type
    when SCAN_COMPLETE
      "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
    when CRITICAL_VULNERABILITY, HIGH_VULNERABILITY
      "M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
    when REPORT_READY
      "M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
    when MEMBER_ADDED
      "M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z"
    when MEMBER_REMOVED
      "M13 7a4 4 0 11-8 0 4 4 0 018 0zM9 14a6 6 0 00-6 6v1h12v-1a6 6 0 00-6-6zM21 12h-6"
    else
      "M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"
    end
  end
end
