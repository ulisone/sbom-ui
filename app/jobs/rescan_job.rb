class RescanJob < ApplicationJob
  queue_as :default

  def perform(scan_id)
    scan = Scan.find(scan_id)
    scan.update!(status: :processing)

    begin
      # Clear existing vulnerabilities
      scan.vulnerabilities.destroy_all

      # Run vulnerability scan with existing SBOM
      scanner = Scanners::TrivyScanner.new(scan.sbom_content, scan.sbom_format)
      vulnerabilities = scanner.scan

      # Save new vulnerabilities
      vulnerabilities.each do |vuln|
        scan.vulnerabilities.create!(
          cve_id: vuln[:cve_id],
          severity: vuln[:severity],
          package_name: vuln[:package_name],
          package_version: vuln[:package_version],
          title: vuln[:title],
          description: vuln[:description],
          fixed_version: vuln[:fixed_version],
          cvss_score: vuln[:cvss_score],
          references: vuln[:references]
        )
      end

      scan.update!(status: :completed, scanned_at: Time.current)

      # Broadcast status update
      Turbo::StreamsChannel.broadcast_replace_to(
        "scan_#{scan.id}",
        target: "scan_status",
        partial: "scans/status",
        locals: { scan: scan }
      )
    rescue Scanners::BaseScanner::ScanError => e
      Rails.logger.warn("Vulnerability rescan failed: #{e.message}")
      scan.update!(status: :completed, scanned_at: Time.current)
    rescue StandardError => e
      scan.update!(status: :failed)
      Rails.logger.error("Rescan failed: #{e.message}\n#{e.backtrace.join("\n")}")
    end
  end
end
