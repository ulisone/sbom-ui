class NotificationService
  def self.notify(user:, type:, title:, message: nil, notifiable: nil, data: {})
    new(user, type, title, message, notifiable, data).deliver
  end

  def self.notify_scan_complete(scan)
    user = scan.project.user
    title = I18n.t("notifications.scan_complete.title", project: scan.project.name)
    message = I18n.t("notifications.scan_complete.message",
      vulnerabilities: scan.total_vulnerabilities,
      critical: scan.vulnerability_summary[:critical],
      high: scan.vulnerability_summary[:high]
    )

    notify(
      user: user,
      type: Notification::SCAN_COMPLETE,
      title: title,
      message: message,
      notifiable: scan,
      data: { project_id: scan.project_id, scan_id: scan.id }
    )
  end

  def self.notify_critical_vulnerability(scan, vulnerability)
    user = scan.project.user
    title = I18n.t("notifications.critical_vulnerability.title")
    message = I18n.t("notifications.critical_vulnerability.message",
      cve: vulnerability.cve_id || "Unknown",
      package: vulnerability.package_name,
      project: scan.project.name
    )

    notify(
      user: user,
      type: Notification::CRITICAL_VULNERABILITY,
      title: title,
      message: message,
      notifiable: vulnerability,
      data: { project_id: scan.project_id, scan_id: scan.id, vulnerability_id: vulnerability.id }
    )
  end

  def self.notify_high_vulnerability(scan, vulnerability)
    user = scan.project.user
    title = I18n.t("notifications.high_vulnerability.title")
    message = I18n.t("notifications.high_vulnerability.message",
      cve: vulnerability.cve_id || "Unknown",
      package: vulnerability.package_name,
      project: scan.project.name
    )

    notify(
      user: user,
      type: Notification::HIGH_VULNERABILITY,
      title: title,
      message: message,
      notifiable: vulnerability,
      data: { project_id: scan.project_id, scan_id: scan.id, vulnerability_id: vulnerability.id }
    )
  end

  def self.notify_report_ready(report)
    user = report.project.user
    title = I18n.t("notifications.report_ready.title")
    message = I18n.t("notifications.report_ready.message",
      type: I18n.t("reports.types.#{report.report_type}"),
      project: report.project.name
    )

    notify(
      user: user,
      type: Notification::REPORT_READY,
      title: title,
      message: message,
      notifiable: report,
      data: { project_id: report.project_id, report_id: report.id }
    )
  end

  def self.notify_member_added(membership)
    title = I18n.t("notifications.member_added.title")
    message = I18n.t("notifications.member_added.message",
      organization: membership.organization.name
    )

    notify(
      user: membership.user,
      type: Notification::MEMBER_ADDED,
      title: title,
      message: message,
      notifiable: membership.organization,
      data: { organization_id: membership.organization_id }
    )
  end

  def initialize(user, type, title, message, notifiable, data)
    @user = user
    @type = type
    @title = title
    @message = message
    @notifiable = notifiable
    @data = data
  end

  def deliver
    return unless should_notify?

    notification = create_notification
    send_email if should_send_email?
    send_webhook if should_send_webhook?

    notification
  end

  private

  attr_reader :user, :type, :title, :message, :notifiable, :data

  def preferences
    @preferences ||= user.notification_preferences
  end

  def should_notify?
    preferences.should_notify?(type)
  end

  def should_send_email?
    preferences.email_enabled?
  end

  def should_send_webhook?
    preferences.webhook_configured?
  end

  def create_notification
    user.notifications.create!(
      notification_type: type,
      title: title,
      message: message,
      notifiable: notifiable,
      data: data
    )
  end

  def send_email
    NotificationMailer.notification_email(user, type, title, message, data).deliver_later
  rescue StandardError => e
    Rails.logger.error("Failed to send notification email: #{e.message}")
  end

  def send_webhook
    WebhookService.send_notification(
      url: preferences.webhook_url,
      type: preferences.webhook_type,
      title: title,
      message: message,
      notification_type: type,
      data: data
    )
  rescue StandardError => e
    Rails.logger.error("Failed to send webhook notification: #{e.message}")
  end
end
