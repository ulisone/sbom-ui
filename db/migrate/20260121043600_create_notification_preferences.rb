class CreateNotificationPreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :notification_preferences do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.boolean :email_enabled, default: true, null: false
      t.boolean :webhook_enabled, default: false, null: false
      t.string :webhook_url
      t.string :webhook_type, default: "slack"
      t.boolean :notify_on_scan_complete, default: true, null: false
      t.boolean :notify_on_critical_vuln, default: true, null: false
      t.boolean :notify_on_high_vuln, default: true, null: false
      t.string :digest_frequency, default: "immediate"

      t.timestamps
    end
  end
end
