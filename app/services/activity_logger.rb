class ActivityLogger
  class << self
    def log(action:, user: nil, trackable: nil, details: {}, request: nil)
      ActivityLog.create!(
        action: action,
        user: user,
        trackable: trackable,
        details: details,
        ip_address: request&.remote_ip,
        user_agent: request&.user_agent&.truncate(500)
      )
    rescue StandardError => e
      Rails.logger.error("Failed to log activity: #{e.message}")
      nil
    end

    # User actions
    def user_signed_in(user, request: nil)
      log(
        action: ActivityLog::USER_SIGNED_IN,
        user: user,
        trackable: user,
        request: request
      )
    end

    def user_signed_out(user, request: nil)
      log(
        action: ActivityLog::USER_SIGNED_OUT,
        user: user,
        trackable: user,
        request: request
      )
    end

    # Project actions
    def project_created(project, user:, request: nil)
      log(
        action: ActivityLog::PROJECT_CREATED,
        user: user,
        trackable: project,
        details: { name: project.name },
        request: request
      )
    end

    def project_updated(project, user:, changes: {}, request: nil)
      log(
        action: ActivityLog::PROJECT_UPDATED,
        user: user,
        trackable: project,
        details: { name: project.name, changes: changes },
        request: request
      )
    end

    def project_deleted(project, user:, request: nil)
      log(
        action: ActivityLog::PROJECT_DELETED,
        user: user,
        trackable: nil,
        details: { name: project.name, id: project.id },
        request: request
      )
    end

    # Scan actions
    def scan_started(scan, user:, request: nil)
      log(
        action: ActivityLog::SCAN_STARTED,
        user: user,
        trackable: scan,
        details: { project_name: scan.project.name },
        request: request
      )
    end

    def scan_completed(scan, user: nil, request: nil)
      log(
        action: ActivityLog::SCAN_COMPLETED,
        user: user || scan.project.user,
        trackable: scan,
        details: {
          project_name: scan.project.name,
          vulnerabilities: scan.total_vulnerabilities,
          dependencies: scan.dependencies.count
        },
        request: request
      )
    end

    def scan_failed(scan, user: nil, error: nil, request: nil)
      log(
        action: ActivityLog::SCAN_FAILED,
        user: user || scan.project.user,
        trackable: scan,
        details: { project_name: scan.project.name, error: error },
        request: request
      )
    end

    # Report actions
    def report_generated(report, user:, request: nil)
      log(
        action: ActivityLog::REPORT_GENERATED,
        user: user,
        trackable: report,
        details: { project_name: report.project.name, type: report.report_type },
        request: request
      )
    end

    def report_downloaded(report, user:, request: nil)
      log(
        action: ActivityLog::REPORT_DOWNLOADED,
        user: user,
        trackable: report,
        details: { project_name: report.project.name, format: report.format },
        request: request
      )
    end

    # Organization actions
    def organization_created(organization, user:, request: nil)
      log(
        action: ActivityLog::ORGANIZATION_CREATED,
        user: user,
        trackable: organization,
        details: { name: organization.name },
        request: request
      )
    end

    def member_added(membership, user:, request: nil)
      log(
        action: ActivityLog::MEMBER_ADDED,
        user: user,
        trackable: membership.organization,
        details: {
          member_email: membership.user.email,
          role: membership.role
        },
        request: request
      )
    end

    def member_removed(organization, removed_user, user:, request: nil)
      log(
        action: ActivityLog::MEMBER_REMOVED,
        user: user,
        trackable: organization,
        details: { member_email: removed_user.email },
        request: request
      )
    end

    def member_role_changed(membership, old_role:, user:, request: nil)
      log(
        action: ActivityLog::MEMBER_ROLE_CHANGED,
        user: user,
        trackable: membership.organization,
        details: {
          member_email: membership.user.email,
          old_role: old_role,
          new_role: membership.role
        },
        request: request
      )
    end

    # Policy actions
    def policy_created(policy, user:, request: nil)
      log(
        action: ActivityLog::POLICY_CREATED,
        user: user,
        trackable: policy,
        details: { name: policy.name, type: policy.policy_type },
        request: request
      )
    end

    def policy_violation(violation, request: nil)
      log(
        action: ActivityLog::POLICY_VIOLATION,
        user: violation.scan.project.user,
        trackable: violation.policy,
        details: {
          violation_type: violation.violation_type,
          severity: violation.severity,
          message: violation.message
        },
        request: request
      )
    end
  end
end
