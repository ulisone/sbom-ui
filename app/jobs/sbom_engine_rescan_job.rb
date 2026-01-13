class SbomEngineRescanJob < ApplicationJob
  queue_as :default

  def perform(scan_id)
    scan = Scan.find(scan_id)

    # Clear existing vulnerabilities before rescan
    scan.vulnerabilities.destroy_all

    SbomEngineScanService.new(scan: scan).perform_vulnerability_scan
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error("Scan not found: #{scan_id}")
  rescue SbomEngineClient::ConnectionError => e
    Rails.logger.error("SBOM Engine connection failed for rescan: #{e.message}")
    scan&.update!(status: :failed)
  rescue SbomEngineClient::ApiError => e
    Rails.logger.error("SBOM Engine API error during rescan: #{e.message}")
    scan&.update!(status: :failed)
  end
end
