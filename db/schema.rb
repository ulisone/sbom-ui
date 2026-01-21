# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_01_21_105343) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activity_logs", force: :cascade do |t|
    t.bigint "user_id"
    t.string "trackable_type"
    t.bigint "trackable_id"
    t.string "action", null: false
    t.jsonb "details", default: {}
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_activity_logs_on_action"
    t.index ["created_at"], name: "index_activity_logs_on_created_at"
    t.index ["trackable_type", "trackable_id", "action"], name: "idx_on_trackable_type_trackable_id_action_b7cb16fa70"
    t.index ["trackable_type", "trackable_id"], name: "index_activity_logs_on_trackable"
    t.index ["user_id"], name: "index_activity_logs_on_user_id"
  end

  create_table "dependencies", force: :cascade do |t|
    t.bigint "scan_id", null: false
    t.string "name"
    t.string "version"
    t.string "ecosystem"
    t.string "purl"
    t.string "license"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scan_id"], name: "index_dependencies_on_scan_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "organization_id", null: false
    t.string "role", default: "member", null: false
    t.bigint "invited_by_id"
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invited_by_id"], name: "index_memberships_on_invited_by_id"
    t.index ["organization_id"], name: "index_memberships_on_organization_id"
    t.index ["role"], name: "index_memberships_on_role"
    t.index ["user_id", "organization_id"], name: "index_memberships_on_user_id_and_organization_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "notification_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.boolean "email_enabled", default: true, null: false
    t.boolean "webhook_enabled", default: false, null: false
    t.string "webhook_url"
    t.string "webhook_type", default: "slack"
    t.boolean "notify_on_scan_complete", default: true, null: false
    t.boolean "notify_on_critical_vuln", default: true, null: false
    t.boolean "notify_on_high_vuln", default: true, null: false
    t.string "digest_frequency", default: "immediate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_notification_preferences_on_user_id", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "notifiable_type"
    t.bigint "notifiable_id"
    t.string "notification_type", null: false
    t.string "title", null: false
    t.text "message"
    t.jsonb "data", default: {}
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["read_at"], name: "index_notifications_on_read_at"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "policies", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "policy_type", null: false
    t.jsonb "rules", default: {}
    t.boolean "enabled", default: true, null: false
    t.bigint "project_id"
    t.bigint "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enabled"], name: "index_policies_on_enabled"
    t.index ["organization_id"], name: "index_policies_on_organization_id"
    t.index ["policy_type"], name: "index_policies_on_policy_type"
    t.index ["project_id"], name: "index_policies_on_project_id"
  end

  create_table "policy_violations", force: :cascade do |t|
    t.bigint "policy_id", null: false
    t.bigint "scan_id", null: false
    t.string "violation_type", null: false
    t.string "severity", null: false
    t.text "message"
    t.jsonb "details", default: {}
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["policy_id"], name: "index_policy_violations_on_policy_id"
    t.index ["resolved_at"], name: "index_policy_violations_on_resolved_at"
    t.index ["scan_id"], name: "index_policy_violations_on_scan_id"
    t.index ["severity"], name: "index_policy_violations_on_severity"
    t.index ["violation_type"], name: "index_policy_violations_on_violation_type"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "repository_url"
    t.bigint "organization_id"
    t.index ["organization_id"], name: "index_projects_on_organization_id"
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "reports", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "scan_id"
    t.string "report_type", default: "summary", null: false
    t.string "status", default: "pending", null: false
    t.string "format", default: "html", null: false
    t.string "title"
    t.text "description"
    t.jsonb "content", default: {}
    t.jsonb "metadata", default: {}
    t.datetime "generated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["format"], name: "index_reports_on_format"
    t.index ["project_id"], name: "index_reports_on_project_id"
    t.index ["report_type"], name: "index_reports_on_report_type"
    t.index ["scan_id"], name: "index_reports_on_scan_id"
    t.index ["status"], name: "index_reports_on_status"
  end

  create_table "scans", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "status"
    t.string "sbom_format"
    t.jsonb "sbom_content"
    t.datetime "scanned_at"
    t.string "file_name"
    t.string "ecosystem"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "scan_mode", default: "local"
    t.index ["project_id"], name: "index_scans_on_project_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vulnerabilities", force: :cascade do |t|
    t.bigint "scan_id", null: false
    t.string "cve_id"
    t.string "severity"
    t.string "package_name"
    t.string "package_version"
    t.string "title"
    t.text "description"
    t.string "fixed_version"
    t.float "cvss_score"
    t.jsonb "references"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scan_id"], name: "index_vulnerabilities_on_scan_id"
  end

  create_table "vulnerability_histories", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "scan_id"
    t.string "vulnerability_id", null: false
    t.string "event_type", null: false
    t.string "severity"
    t.string "package_name"
    t.string "old_version"
    t.string "new_version"
    t.jsonb "details", default: {}
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_type"], name: "index_vulnerability_histories_on_event_type"
    t.index ["occurred_at"], name: "index_vulnerability_histories_on_occurred_at"
    t.index ["project_id"], name: "index_vulnerability_histories_on_project_id"
    t.index ["scan_id"], name: "index_vulnerability_histories_on_scan_id"
    t.index ["severity"], name: "index_vulnerability_histories_on_severity"
    t.index ["vulnerability_id"], name: "index_vulnerability_histories_on_vulnerability_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_logs", "users"
  add_foreign_key "dependencies", "scans"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users"
  add_foreign_key "memberships", "users", column: "invited_by_id"
  add_foreign_key "notification_preferences", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "policies", "organizations"
  add_foreign_key "policies", "projects"
  add_foreign_key "policy_violations", "policies"
  add_foreign_key "policy_violations", "scans"
  add_foreign_key "projects", "organizations"
  add_foreign_key "projects", "users"
  add_foreign_key "reports", "projects"
  add_foreign_key "reports", "scans"
  add_foreign_key "scans", "projects"
  add_foreign_key "vulnerabilities", "scans"
  add_foreign_key "vulnerability_histories", "projects"
  add_foreign_key "vulnerability_histories", "scans"
end
