class ActivityLog < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :trackable, polymorphic: true, optional: true

  # Action types
  # User actions
  USER_SIGNED_IN = "user.signed_in".freeze
  USER_SIGNED_OUT = "user.signed_out".freeze
  USER_CREATED = "user.created".freeze
  USER_UPDATED = "user.updated".freeze

  # Project actions
  PROJECT_CREATED = "project.created".freeze
  PROJECT_UPDATED = "project.updated".freeze
  PROJECT_DELETED = "project.deleted".freeze

  # Scan actions
  SCAN_STARTED = "scan.started".freeze
  SCAN_COMPLETED = "scan.completed".freeze
  SCAN_FAILED = "scan.failed".freeze

  # Report actions
  REPORT_GENERATED = "report.generated".freeze
  REPORT_DOWNLOADED = "report.downloaded".freeze

  # Organization actions
  ORGANIZATION_CREATED = "organization.created".freeze
  ORGANIZATION_UPDATED = "organization.updated".freeze
  ORGANIZATION_DELETED = "organization.deleted".freeze
  MEMBER_ADDED = "organization.member_added".freeze
  MEMBER_REMOVED = "organization.member_removed".freeze
  MEMBER_ROLE_CHANGED = "organization.member_role_changed".freeze

  # Policy actions
  POLICY_CREATED = "policy.created".freeze
  POLICY_UPDATED = "policy.updated".freeze
  POLICY_DELETED = "policy.deleted".freeze
  POLICY_VIOLATION = "policy.violation".freeze

  validates :action, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_action, ->(action) { where(action: action) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_trackable, ->(trackable) { where(trackable: trackable) }
  scope :today, -> { where(created_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :this_week, -> { where(created_at: 1.week.ago..Time.current) }
  scope :this_month, -> { where(created_at: 1.month.ago..Time.current) }

  def action_category
    action.split(".").first
  end

  def action_name
    action.split(".").last
  end

  def action_display
    I18n.t("activity_logs.actions.#{action.gsub('.', '_')}", default: action.titleize)
  end

  def trackable_display
    return nil unless trackable

    case trackable_type
    when "Project"
      trackable.name
    when "Scan"
      "##{trackable.id}"
    when "Report"
      trackable.title || "##{trackable.id}"
    when "Organization"
      trackable.name
    when "Policy"
      trackable.name
    when "User"
      trackable.display_name
    else
      "##{trackable_id}"
    end
  rescue
    "##{trackable_id}"
  end

  def icon_class
    case action_category
    when "user"
      "text-primary"
    when "project"
      "text-medium"
    when "scan"
      action_name == "failed" ? "text-critical" : "text-low"
    when "report"
      "text-primary"
    when "organization"
      "text-high"
    when "policy"
      action_name == "violation" ? "text-critical" : "text-medium"
    else
      "text-text-muted"
    end
  end

  def icon_path
    case action_category
    when "user"
      "M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
    when "project"
      "M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z"
    when "scan"
      "M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"
    when "report"
      "M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
    when "organization"
      "M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
    when "policy"
      "M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
    else
      "M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
    end
  end
end
