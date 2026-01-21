class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: [:show, :mark_as_read]

  def index
    @notifications = current_user.notifications.recent.limit(50)
    @unread_count = current_user.unread_notifications_count
  end

  def show
    @notification.mark_as_read!
    redirect_to notification_target_path(@notification)
  end

  def mark_as_read
    @notification.mark_as_read!

    respond_to do |format|
      format.html { redirect_back(fallback_location: notifications_path) }
      format.turbo_stream
    end
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read_at: Time.current)

    respond_to do |format|
      format.html { redirect_to notifications_path, notice: t("notifications.all_marked_as_read") }
      format.turbo_stream
    end
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end

  def notification_target_path(notification)
    case notification.notification_type
    when Notification::SCAN_COMPLETE
      notification.data["scan_id"] ? scan_path(notification.data["scan_id"]) : notifications_path
    when Notification::CRITICAL_VULNERABILITY, Notification::HIGH_VULNERABILITY
      notification.data["vulnerability_id"] ? vulnerability_path(notification.data["vulnerability_id"]) : notifications_path
    when Notification::REPORT_READY
      notification.data["report_id"] ? report_path(notification.data["report_id"]) : notifications_path
    when Notification::MEMBER_ADDED
      notification.data["organization_id"] ? organization_path(notification.data["organization_id"]) : notifications_path
    else
      notifications_path
    end
  end
end
