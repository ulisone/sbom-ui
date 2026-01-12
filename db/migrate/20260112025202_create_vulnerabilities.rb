class CreateVulnerabilities < ActiveRecord::Migration[8.0]
  def change
    create_table :vulnerabilities do |t|
      t.references :scan, null: false, foreign_key: true
      t.string :cve_id
      t.string :severity
      t.string :package_name
      t.string :package_version
      t.string :title
      t.text :description
      t.string :fixed_version
      t.float :cvss_score
      t.jsonb :references

      t.timestamps
    end
  end
end
