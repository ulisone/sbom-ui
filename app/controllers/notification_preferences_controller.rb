class NotificationPreferencesController < ApplicationController
  before_action :authenticate_user!

  def edit
    @preference = current_user.notification_preferences
  end

  def update
    @preference = current_user.notification_preferences

    if @preference.update(preference_params)
      redirect_to edit_notification_preferences_path, notice: t("notification_preferences.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def test_webhook
    @preference = current_user.notification_preferences

    unless @preference.webhook_configured?
      redirect_to edit_notification_preferences_path, alert: t("notification_preferences.webhook_not_configured")
      return
    end

    result = WebhookService.send_notification(
      url: @preference.webhook_url,
      type: @preference.webhook_type,
      title: t("notification_preferences.test_webhook_title"),
      message: t("notification_preferences.test_webhook_message"),
      notification_type: Notification::SCAN_COMPLETE,
      data: { test: true }
    )

    if result&.is_a?(Net::HTTPSuccess)
      redirect_to edit_notification_preferences_path, notice: t("notification_preferences.webhook_test_success")
    else
      redirect_to edit_notification_preferences_path, alert: t("notification_preferences.webhook_test_failed")
    end
  end

  private

  def preference_params
    params.require(:notification_preference).permit(
      :email_enabled,
      :webhook_enabled,
      :webhook_url,
      :webhook_type,
      :notify_on_scan_complete,
      :notify_on_critical_vuln,
      :notify_on_high_vuln,
      :digest_frequency
    )
  end
end
