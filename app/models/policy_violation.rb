class PolicyViolation < ApplicationRecord
  belongs_to :policy
  belongs_to :scan

  SEVERITIES = %w[critical high medium low].freeze

  validates :violation_type, presence: true
  validates :severity, presence: true, inclusion: { in: SEVERITIES }

  scope :unresolved, -> { where(resolved_at: nil) }
  scope :resolved, -> { where.not(resolved_at: nil) }
  scope :critical, -> { where(severity: "critical") }
  scope :high, -> { where(severity: "high") }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_severity, ->(severity) { where(severity: severity) }

  def resolved?
    resolved_at.present?
  end

  def unresolved?
    resolved_at.nil?
  end

  def resolve!
    update!(resolved_at: Time.current) unless resolved?
  end

  def unresolve!
    update!(resolved_at: nil) if resolved?
  end

  def severity_class
    case severity
    when "critical" then "badge-critical"
    when "high" then "badge-high"
    when "medium" then "badge-medium"
    when "low" then "badge-low"
    else "badge"
    end
  end

  def severity_display
    I18n.t("vulnerabilities.severity.#{severity}")
  end

  def type_display
    I18n.t("policies.violation_types.#{violation_type}", default: violation_type.titleize)
  end
end
