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

ActiveRecord::Schema[8.0].define(version: 2026_01_12_070515) do
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

  create_table "projects", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "repository_url"
    t.index ["user_id"], name: "index_projects_on_user_id"
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "dependencies", "scans"
  add_foreign_key "projects", "users"
  add_foreign_key "scans", "projects"
  add_foreign_key "vulnerabilities", "scans"
end
