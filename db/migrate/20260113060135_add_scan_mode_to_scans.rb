class AddScanModeToScans < ActiveRecord::Migration[8.0]
  def change
    add_column :scans, :scan_mode, :string, default: "local"
  end
end
