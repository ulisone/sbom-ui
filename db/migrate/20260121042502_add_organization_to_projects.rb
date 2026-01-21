class AddOrganizationToProjects < ActiveRecord::Migration[8.0]
  def change
    add_reference :projects, :organization, null: true, foreign_key: true
  end
end
