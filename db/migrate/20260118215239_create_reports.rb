class CreateReports < ActiveRecord::Migration[8.0]
  def change
    create_table :reports do |t|
      t.references :project, null: false, foreign_key: true
      t.references :scan, foreign_key: true
      t.string :report_type, null: false, default: "summary" # summary, detailed, executive, compliance
      t.string :status, null: false, default: "pending" # pending, generating, completed, failed
      t.string :format, null: false, default: "html" # html, pdf, csv, json
      t.string :title
      t.text :description
      t.jsonb :content, default: {}
      t.jsonb :metadata, default: {}
      t.datetime :generated_at

      t.timestamps
    end

    add_index :reports, :report_type
    add_index :reports, :status
    add_index :reports, :format
  end
end
