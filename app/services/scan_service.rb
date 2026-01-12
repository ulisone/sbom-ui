class ScanService
  attr_reader :scan

  def initialize(scan:)
    @scan = scan
  end

  def perform
    update_status(:processing)

    # Step 1: Parse dependencies from all attached files
    dependencies = parse_all_dependencies

    # Step 2: Save dependencies to the database
    save_dependencies(dependencies)

    # Step 3: Generate SBOM
    sbom = generate_sbom(dependencies)

    # Step 4: Save SBOM content
    scan.update!(sbom_content: sbom)

    # Step 5: Scan for vulnerabilities
    vulnerabilities = scan_vulnerabilities(sbom)

    # Step 6: Save vulnerabilities
    save_vulnerabilities(vulnerabilities)

    # Step 7: Mark scan as completed
    update_status(:completed, scanned_at: Time.current)

    scan
  rescue StandardError => e
    update_status(:failed)
    Rails.logger.error("Scan failed: #{e.message}\n#{e.backtrace.join("\n")}")
    raise
  end

  def update_status(status, **additional_attrs)
    scan.update!(status: status, **additional_attrs)
    broadcast_status_update
  end

  def broadcast_status_update
    Turbo::StreamsChannel.broadcast_replace_to(
      "scan_#{scan.id}",
      target: "scan_status",
      partial: "scans/status",
      locals: { scan: scan }
    )
  end

  private

  def parse_all_dependencies
    all_dependencies = []
    ecosystems = []

    scan.dependency_files.each do |file|
      file_name = file.filename.to_s
      file_content = file.download

      begin
        parser = Parsers::BaseParser.for(file_name, file_content)
        ecosystems << parser.ecosystem
        dependencies = parser.parse
        all_dependencies.concat(dependencies)
      rescue Parsers::BaseParser::UnsupportedFileError => e
        Rails.logger.warn("Skipping unsupported file: #{file_name}")
      end
    end

    # Set the primary ecosystem (first one or mixed if multiple)
    scan.update!(ecosystem: ecosystems.uniq.join(","))

    # Remove duplicates by name+version+ecosystem
    all_dependencies.uniq { |d| [d[:name], d[:version], d[:ecosystem]] }
  end

  def save_dependencies(dependencies)
    dependencies.each do |dep|
      scan.dependencies.create!(
        name: dep[:name],
        version: dep[:version],
        ecosystem: dep[:ecosystem],
        purl: dep[:purl],
        license: dep[:license]
      )
    end
  end

  def generate_sbom(dependencies)
    generator_class = case scan.sbom_format
    when "cyclonedx"
      Sbom::CyclonedxGenerator
    when "spdx"
      Sbom::SpdxGenerator
    else
      Sbom::CyclonedxGenerator # Default to CycloneDX
    end

    metadata = {
      component_name: scan.project.name,
      component_version: "1.0.0",
      document_name: "#{scan.project.name} SBOM"
    }

    generator = generator_class.new(dependencies, metadata)
    generator.generate
  end

  def scan_vulnerabilities(sbom)
    scanner = Scanners::TrivyScanner.new(sbom, scan.sbom_format)
    scanner.scan
  rescue Scanners::BaseScanner::ScanError => e
    Rails.logger.warn("Vulnerability scan failed: #{e.message}")
    [] # Return empty if scan fails
  end

  def save_vulnerabilities(vulnerabilities)
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
  end
end
