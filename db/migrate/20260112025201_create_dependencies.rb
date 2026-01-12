class CreateDependencies < ActiveRecord::Migration[8.0]
  def change
    create_table :dependencies do |t|
      t.references :scan, null: false, foreign_key: true
      t.string :name
      t.string :version
      t.string :ecosystem
      t.string :purl
      t.string :license

      t.timestamps
    end
  end
end
