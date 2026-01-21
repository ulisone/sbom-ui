class PolicyCheckerService
  def self.check(scan)
    new(scan).check
  end

  def initialize(scan)
    @scan = scan
    @project = scan.project
    @violations = []
  end

  def check
    return [] unless @project

    applicable_policies.each do |policy|
      new_violations = policy.check_scan(@scan)
      @violations.concat(new_violations)
    end

    save_violations
    notify_if_critical

    @violations
  end

  private

  def applicable_policies
    policies = Policy.enabled

    # Project-specific policies
    project_policies = policies.where(project: @project)

    # Organization-wide policies
    org_policies = if @project.organization
                     policies.where(organization: @project.organization, project: nil)
                   else
                     Policy.none
                   end

    project_policies.or(org_policies)
  end

  def save_violations
    PolicyViolation.transaction do
      @violations.each(&:save!)
    end
  end

  def notify_if_critical
    critical_violations = @violations.select { |v| v.severity == "critical" }
    return if critical_violations.empty?

    # Notify project owner
    NotificationService.notify(
      user: @project.user,
      type: Notification::CRITICAL_VULNERABILITY,
      title: I18n.t("policies.notifications.violations_detected"),
      message: I18n.t("policies.notifications.critical_violations",
        count: critical_violations.count,
        project: @project.name
      ),
      notifiable: @scan,
      data: {
        project_id: @project.id,
        scan_id: @scan.id,
        violation_count: critical_violations.count
      }
    )
  end
end
