class CreateScans < ActiveRecord::Migration[8.0]
  def change
    create_table :scans do |t|
      t.references :project, null: false, foreign_key: true
      t.string :status
      t.string :sbom_format
      t.jsonb :sbom_content
      t.datetime :scanned_at
      t.string :file_name
      t.string :ecosystem

      t.timestamps
    end
  end
end
