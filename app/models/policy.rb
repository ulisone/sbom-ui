class Policy < ApplicationRecord
  belongs_to :project, optional: true
  belongs_to :organization, optional: true
  has_many :policy_violations, dependent: :destroy

  # Policy types
  VULNERABILITY_THRESHOLD = "vulnerability_threshold".freeze
  LICENSE_ALLOWLIST = "license_allowlist".freeze
  LICENSE_BLOCKLIST = "license_blocklist".freeze
  DEPENDENCY_BLOCKLIST = "dependency_blocklist".freeze
  RISK_SCORE_LIMIT = "risk_score_limit".freeze

  TYPES = [
    VULNERABILITY_THRESHOLD,
    LICENSE_ALLOWLIST,
    LICENSE_BLOCKLIST,
    DEPENDENCY_BLOCKLIST,
    RISK_SCORE_LIMIT
  ].freeze

  validates :name, presence: true
  validates :policy_type, presence: true, inclusion: { in: TYPES }
  validate :must_have_scope

  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }
  scope :by_type, ->(type) { where(policy_type: type) }
  scope :for_project, ->(project) { where(project: project).or(where(organization: project.organization)) }
  scope :global, -> { where(project: nil, organization: nil) }

  # Rule accessors for vulnerability threshold
  def max_critical
    rules["max_critical"]&.to_i
  end

  def max_high
    rules["max_high"]&.to_i
  end

  def max_medium
    rules["max_medium"]&.to_i
  end

  def max_low
    rules["max_low"]&.to_i
  end

  # Rule accessors for license policies
  def license_list
    rules["licenses"] || []
  end

  # Rule accessors for dependency blocklist
  def blocked_packages
    rules["packages"] || []
  end

  # Rule accessors for risk score
  def max_risk_score
    rules["max_score"]&.to_f || 100.0
  end

  def check_scan(scan)
    return [] unless enabled?

    case policy_type
    when VULNERABILITY_THRESHOLD
      check_vulnerability_threshold(scan)
    when LICENSE_ALLOWLIST
      check_license_allowlist(scan)
    when LICENSE_BLOCKLIST
      check_license_blocklist(scan)
    when DEPENDENCY_BLOCKLIST
      check_dependency_blocklist(scan)
    when RISK_SCORE_LIMIT
      check_risk_score_limit(scan)
    else
      []
    end
  end

  def type_display
    I18n.t("policies.types.#{policy_type}")
  end

  private

  def must_have_scope
    if project.nil? && organization.nil?
      errors.add(:base, "Policy must be associated with a project or organization")
    end
  end

  def check_vulnerability_threshold(scan)
    violations = []
    summary = scan.vulnerability_summary

    if max_critical && summary[:critical] > max_critical
      violations << build_violation(
        scan: scan,
        type: "critical_threshold_exceeded",
        severity: "critical",
        message: I18n.t("policies.violations.critical_exceeded", count: summary[:critical], max: max_critical),
        details: { actual: summary[:critical], threshold: max_critical }
      )
    end

    if max_high && summary[:high] > max_high
      violations << build_violation(
        scan: scan,
        type: "high_threshold_exceeded",
        severity: "high",
        message: I18n.t("policies.violations.high_exceeded", count: summary[:high], max: max_high),
        details: { actual: summary[:high], threshold: max_high }
      )
    end

    violations
  end

  def check_license_allowlist(scan)
    violations = []
    allowed = license_list.map(&:downcase)

    scan.dependencies.each do |dep|
      next if dep.license.blank?
      next if allowed.include?(dep.license.downcase)

      violations << build_violation(
        scan: scan,
        type: "license_not_allowed",
        severity: "medium",
        message: I18n.t("policies.violations.license_not_allowed", license: dep.license, package: dep.name),
        details: { package: dep.name, version: dep.version, license: dep.license }
      )
    end

    violations
  end

  def check_license_blocklist(scan)
    violations = []
    blocked = license_list.map(&:downcase)

    scan.dependencies.each do |dep|
      next if dep.license.blank?
      next unless blocked.include?(dep.license.downcase)

      violations << build_violation(
        scan: scan,
        type: "license_blocked",
        severity: "high",
        message: I18n.t("policies.violations.license_blocked", license: dep.license, package: dep.name),
        details: { package: dep.name, version: dep.version, license: dep.license }
      )
    end

    violations
  end

  def check_dependency_blocklist(scan)
    violations = []

    blocked_packages.each do |blocked|
      scan.dependencies.where("name ILIKE ?", blocked["name"]).each do |dep|
        violations << build_violation(
          scan: scan,
          type: "package_blocked",
          severity: blocked["severity"] || "high",
          message: I18n.t("policies.violations.package_blocked", package: dep.name, reason: blocked["reason"]),
          details: { package: dep.name, version: dep.version, reason: blocked["reason"] }
        )
      end
    end

    violations
  end

  def check_risk_score_limit(scan)
    violations = []
    score = scan.calculate_risk_score

    if score > max_risk_score
      violations << build_violation(
        scan: scan,
        type: "risk_score_exceeded",
        severity: score > 80 ? "critical" : "high",
        message: I18n.t("policies.violations.risk_score_exceeded", score: score.round(1), max: max_risk_score),
        details: { actual_score: score, threshold: max_risk_score }
      )
    end

    violations
  end

  def build_violation(scan:, type:, severity:, message:, details: {})
    policy_violations.build(
      scan: scan,
      violation_type: type,
      severity: severity,
      message: message,
      details: details
    )
  end
end
