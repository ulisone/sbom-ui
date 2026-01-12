module Scanners
  class TrivyScanner < BaseScanner
    TRIVY_CONTAINER = "sbom_dashboard_trivy"

    def scan
      # Write SBOM to shared volume
      filename = "#{SecureRandom.uuid}.json"
      host_path = Rails.root.join("tmp", "scans", filename)
      container_path = "/scans/#{filename}"

      begin
        # Ensure directory exists
        FileUtils.mkdir_p(host_path.dirname)

        # Write SBOM content
        File.write(host_path, sbom_content.to_json)

        # Run Trivy scan via Docker
        result = scan_with_docker(container_path)
        parse_results(result)
      ensure
        FileUtils.rm_f(host_path)
      end
    end

    private

    def scan_with_docker(container_path)
      # Run trivy sbom scan inside the container
      cmd = "docker exec #{TRIVY_CONTAINER} trivy sbom --format json --quiet #{container_path} 2>&1"
      output = `#{cmd}`

      unless $?.success?
        Rails.logger.error("Trivy scan failed: #{output}")
        raise ScanError, "Trivy scan failed: #{output}"
      end

      # Parse JSON output
      JSON.parse(output)
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse Trivy output: #{output}")
      raise ScanError, "Failed to parse Trivy output: #{e.message}"
    end

    def parse_results(result)
      vulnerabilities = []

      # Handle different Trivy output formats
      results = result["Results"] || result["results"] || []

      results.each do |target_result|
        vulns = target_result["Vulnerabilities"] || target_result["vulnerabilities"] || []

        vulns.each do |vuln|
          vulnerabilities << {
            cve_id: vuln["VulnerabilityID"] || vuln["vulnerabilityID"],
            severity: normalize_severity(vuln["Severity"] || vuln["severity"]),
            package_name: vuln["PkgName"] || vuln["pkgName"],
            package_version: vuln["InstalledVersion"] || vuln["installedVersion"],
            title: vuln["Title"] || vuln["title"],
            description: vuln["Description"] || vuln["description"],
            fixed_version: vuln["FixedVersion"] || vuln["fixedVersion"],
            cvss_score: extract_cvss_score(vuln),
            references: extract_references(vuln)
          }
        end
      end

      vulnerabilities
    end

    def normalize_severity(severity)
      return "UNKNOWN" unless severity

      s = severity.to_s.upcase
      %w[CRITICAL HIGH MEDIUM LOW].include?(s) ? s : "UNKNOWN"
    end

    def extract_cvss_score(vuln)
      # Try CVSS v3 first, then v2
      cvss = vuln["CVSS"] || vuln["cvss"] || {}

      if cvss["nvd"]
        cvss["nvd"]["V3Score"] || cvss["nvd"]["V2Score"]
      elsif cvss["redhat"]
        cvss["redhat"]["V3Score"] || cvss["redhat"]["V2Score"]
      else
        nil
      end
    end

    def extract_references(vuln)
      refs = vuln["References"] || vuln["references"] || []
      refs.is_a?(Array) ? refs : []
    end
  end
end
