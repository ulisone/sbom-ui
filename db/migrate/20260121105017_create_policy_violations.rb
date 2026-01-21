class CreatePolicyViolations < ActiveRecord::Migration[8.0]
  def change
    create_table :policy_violations do |t|
      t.references :policy, null: false, foreign_key: true
      t.references :scan, null: false, foreign_key: true
      t.string :violation_type, null: false
      t.string :severity, null: false
      t.text :message
      t.jsonb :details, default: {}
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :policy_violations, :violation_type
    add_index :policy_violations, :severity
    add_index :policy_violations, :resolved_at
  end
end
