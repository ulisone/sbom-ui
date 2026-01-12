class ScanJob < ApplicationJob
  queue_as :default

  def perform(scan_id)
    scan = Scan.find(scan_id)

    ScanService.new(scan: scan).perform
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error("Scan not found: #{scan_id}")
  end
end
