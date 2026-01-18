class ScanService
  attr_reader :scan

  def initialize(scan:)
    @scan = scan
  end

  def perform
    update_status(:processing)

    if scan.use_sbom_engine?
      perform_with_sbom_engine
    else
      perform_local_local
    end

    scan
  rescue StandardError => e
    update_status(:failed)
    Rails.logger.error("Scan failed: #{e.message}\n#{e.backtrace.join("\n")}")
    raise
  end

  def perform_local_local
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
  end

  def perform_with_sbom_engine
    scanner = Scanners::SbomEngineScanner.new(scan)
    result = scanner.perform

    sbom_data = result["sbom"]
    vuln_data = result["vuln"]

    # Save SBOM
    scan.update!(sbom_content: sbom_data)

    # Process and save dependencies from (CycloneDX) SBOM
    if sbom_data && sbom_data["components"]
      save_dependencies_from_sbom(sbom_data["components"])
    end

    # Process and save vulnerabilities
    if vuln_data
      save_engine_vulnerabilities(vuln_data)
    end

    update_status(:completed, scanned_at: Time.current)
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

  def save_dependencies_from_sbom(components)
    components.each do |comp|
      # Try to map CycloneDX component fields to our dependency model
      scan.dependencies.create!(
        name: comp["name"],
        version: comp["version"],
        ecosystem: extract_ecosystem_from_purl(comp["purl"]),
        purl: comp["purl"],
        license: comp["licenses"]&.first&.dig("license", "id")
      )
    end
  end

  def save_engine_vulnerabilities(vulns)
    vulns.each do |v|
      # Map Engine vulnerability format to our DB
      # Engine structure:
      # { "id": "CVE-...", "ratings": [{"severity": "High", "score": 7.5}], "description": "...", "affects": [...] }
      
      rating = v["ratings"]&.first || {}
      
      # Find affected package info from 'affects' array if possible
      # Or just fill what we can. The engine response might link back to component ref.
      # For now, we take the first affected component's version or generic info.
      
      affected = v["affects"]&.first || {}
      affected_version = affected["versions"]&.first&.dig("version")
      ref_id = affected["ref"]

      # Find package name from SBOM link if ref_id exists (requires looking up sbom components)
      # Simpler approach: If engine provides flat package info, use it. 
      # Looking at manual: 
      # "affects": [ { "ref": "component-id", "versions": [...] } ]
      # We might need to look up the component name from the SBOM using ref.
      # For MVP, let's try to pass package name if available or fallback.
      
      scan.vulnerabilities.create!(
        cve_id: v["id"],
        severity: rating["severity"]&.upcase || "UNKNOWN",
        package_name: find_component_name(ref_id), # We need to access sbom content or pass it
        package_version: affected_version,
        title: v["id"], # Engine might not return title separately, use ID
        description: v["description"],
        fixed_version: nil, # Engine might not provide fixed version in this structure easily
        cvss_score: rating["score"],
        references: [] # Engine source link could be added
      )
    end
  end

  def extract_ecosystem_from_purl(purl)
    return "unknown" unless purl
    # pkg:npm/foo@1.0 -> npm
    purl.split("/").first.gsub("pkg:", "")
  rescue
    "unknown"
  end

  def find_component_name(ref_id)
    return nil unless ref_id
    # Optimize: This involves searching the SBOm content which is already saved/in-memory
    # For now, return ref_id or placeholder if lookup is too expensive/complex here
    ref_id
  end
end
