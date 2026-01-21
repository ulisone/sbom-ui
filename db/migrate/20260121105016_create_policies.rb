class CreatePolicies < ActiveRecord::Migration[8.0]
  def change
    create_table :policies do |t|
      t.string :name, null: false
      t.text :description
      t.string :policy_type, null: false
      t.jsonb :rules, default: {}
      t.boolean :enabled, default: true, null: false
      t.references :project, foreign_key: true
      t.references :organization, foreign_key: true

      t.timestamps
    end

    add_index :policies, :policy_type
    add_index :policies, :enabled
  end
end
