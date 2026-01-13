class SbomEngineScanJob < ApplicationJob
  queue_as :default

  def perform(scan_id)
    scan = Scan.find(scan_id)

    SbomEngineScanService.new(scan: scan).perform
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error("Scan not found: #{scan_id}")
  rescue SbomEngineClient::ConnectionError => e
    Rails.logger.error("SBOM Engine connection failed: #{e.message}")
    scan&.update!(status: :failed)
    # Could fallback to local scan here if desired
  rescue SbomEngineClient::ApiError => e
    Rails.logger.error("SBOM Engine API error: #{e.message}")
    scan&.update!(status: :failed)
  end
end
