class NotificationMailer < ApplicationMailer
  def notification_email(user, type, title, message, data)
    @user = user
    @type = type
    @title = title
    @message = message
    @data = data
    @url = notification_url(type, data)

    mail(
      to: user.email,
      subject: "[SBOM Dashboard] #{title}"
    )
  end

  def scan_complete_email(user, scan)
    @user = user
    @scan = scan
    @project = scan.project
    @summary = scan.vulnerability_summary

    mail(
      to: user.email,
      subject: I18n.t("notifications.scan_complete.email_subject", project: @project.name)
    )
  end

  def vulnerability_alert_email(user, scan, vulnerabilities)
    @user = user
    @scan = scan
    @project = scan.project
    @vulnerabilities = vulnerabilities

    mail(
      to: user.email,
      subject: I18n.t("notifications.vulnerability_alert.email_subject",
        count: vulnerabilities.count,
        project: @project.name
      )
    )
  end

  def weekly_digest_email(user, data)
    @user = user
    @data = data

    mail(
      to: user.email,
      subject: I18n.t("notifications.weekly_digest.email_subject")
    )
  end

  private

  def notification_url(type, data)
    case type
    when Notification::SCAN_COMPLETE
      scan_url(data[:scan_id]) if data[:scan_id]
    when Notification::CRITICAL_VULNERABILITY, Notification::HIGH_VULNERABILITY
      vulnerability_url(data[:vulnerability_id]) if data[:vulnerability_id]
    when Notification::REPORT_READY
      report_url(data[:report_id]) if data[:report_id]
    when Notification::MEMBER_ADDED
      organization_url(data[:organization_id]) if data[:organization_id]
    else
      root_url
    end
  end
end
