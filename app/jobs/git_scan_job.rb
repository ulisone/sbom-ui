class GitScanJob < ApplicationJob
  queue_as :default

  def perform(scan_id)
    scan = Scan.find(scan_id)
    project = scan.project

    raise "No repository URL configured" if project.repository_url.blank?

    git_service = GitRepositoryService.new(project.repository_url)

    begin
      # Clone and find dependency files
      dependency_files = git_service.clone_and_scan

      if dependency_files.empty?
        scan.update!(status: :failed)
        Rails.logger.error("No dependency files found in repository: #{project.repository_url}")
        return
      end

      # Process each dependency file
      scan.update!(status: :processing)
      all_dependencies = []
      ecosystems = []

      dependency_files.each do |file|
        begin
          parser = Parsers::BaseParser.for(file[:name], file[:content])
          ecosystems << parser.ecosystem
          dependencies = parser.parse
          all_dependencies.concat(dependencies)
        rescue Parsers::BaseParser::UnsupportedFileError => e
          Rails.logger.warn("Skipping unsupported file: #{file[:name]}")
        end
      end

      # Set ecosystem
      scan.update!(ecosystem: ecosystems.uniq.join(","))

      # Remove duplicates
      all_dependencies = all_dependencies.uniq { |d| [d[:name], d[:version], d[:ecosystem]] }

      # Save dependencies
      all_dependencies.each do |dep|
        scan.dependencies.create!(
          name: dep[:name],
          version: dep[:version],
          ecosystem: dep[:ecosystem],
          purl: dep[:purl],
          license: dep[:license]
        )
      end

      # Generate SBOM
      generator_class = scan.sbom_format == "spdx" ? Sbom::SpdxGenerator : Sbom::CyclonedxGenerator
      metadata = {
        component_name: project.name,
        component_version: "1.0.0",
        document_name: "#{project.name} SBOM"
      }
      sbom = generator_class.new(all_dependencies, metadata).generate
      scan.update!(sbom_content: sbom)

      # Scan for vulnerabilities
      begin
        scanner = Scanners::TrivyScanner.new(sbom, scan.sbom_format)
        vulnerabilities = scanner.scan

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
      rescue Scanners::BaseScanner::ScanError => e
        Rails.logger.warn("Vulnerability scan failed: #{e.message}")
      end

      scan.update!(status: :completed, scanned_at: Time.current)

    rescue GitRepositoryService::GitError => e
      scan.update!(status: :failed)
      Rails.logger.error("Git clone failed: #{e.message}")
    rescue StandardError => e
      scan.update!(status: :failed)
      Rails.logger.error("Git scan failed: #{e.message}\n#{e.backtrace.join("\n")}")
    end
  end
end
