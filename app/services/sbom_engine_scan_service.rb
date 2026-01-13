# SBOM Engine Scan Service
# Uses SBOM Engine API for scanning software and querying vulnerabilities
class SbomEngineScanService
  attr_reader :scan, :client

  POLL_INTERVAL = 2 # seconds
  MAX_POLL_ATTEMPTS = 300 # 10 minutes maximum

  def initialize(scan:)
    @scan = scan
    @client = SbomEngineClient.new
  end

  def perform
    update_status(:processing)

    # Step 1: Check if SBOM Engine is available
    unless client.available?
      raise SbomEngineClient::ConnectionError, "SBOM Engine is not available"
    end

    # Step 2: Upload files and get path
    upload_path = upload_files

    # Step 3: Request inspection
    task_id = request_inspection(upload_path)

    # Step 4: Wait for inspection to complete
    wait_for_completion(task_id)

    # Step 5: Get and process results
    process_results(task_id)

    # Step 6: Mark scan as completed
    update_status(:completed, scanned_at: Time.current)

    scan
  rescue SbomEngineClient::ApiError, SbomEngineClient::ConnectionError => e
    update_status(:failed)
    Rails.logger.error("SBOM Engine scan failed: #{e.message}")
    raise
  rescue StandardError => e
    update_status(:failed)
    Rails.logger.error("Scan failed: #{e.message}\n#{e.backtrace.join("\n")}")
    raise
  end

  # Perform vulnerability-only scan using existing SBOM
  def perform_vulnerability_scan
    update_status(:processing)

    unless client.available?
      raise SbomEngineClient::ConnectionError, "SBOM Engine is not available"
    end

    # Use existing SBOM content for vulnerability check
    if scan.sbom_content.blank?
      raise SbomEngineClient::ApiError, "No SBOM content available for vulnerability scan"
    end

    # Create temp file with SBOM content
    upload_path = upload_sbom_content

    # Request vulnerability check only
    task_id = client.request_inspect(path: upload_path, type: :check)

    wait_for_completion(task_id)

    # Get and save only vulnerability results
    result = client.inspect_result(
      task_id: task_id,
      sbom_type: client.normalize_sbom_format(scan.sbom_format)
    )

    save_vulnerabilities_from_result(result)

    update_status(:completed, scanned_at: Time.current)
    scan
  rescue StandardError => e
    update_status(:failed)
    Rails.logger.error("Vulnerability scan failed: #{e.message}")
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

  def upload_files
    if scan.dependency_files.attached?
      # Upload multiple files as a zip or individually
      upload_dependency_files
    elsif scan.project.repository_url.present?
      # For repository scans, we need to clone and zip first
      upload_from_repository
    else
      raise SbomEngineClient::ApiError, "No files or repository to scan"
    end
  end

  def upload_dependency_files
    if scan.dependency_files.count == 1
      # Single file upload
      client.upload_attachment(scan.dependency_files.first)
    else
      # Multiple files - create a zip
      create_and_upload_zip
    end
  end

  def create_and_upload_zip
    Dir.mktmpdir do |dir|
      zip_path = File.join(dir, "dependencies.zip")

      Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
        scan.dependency_files.each do |file|
          zipfile.get_output_stream(file.filename.to_s) do |out|
            out.write(file.download)
          end
        end
      end

      client.upload_file(file_path: zip_path, filename: "dependencies.zip")
    end
  end

  def upload_from_repository
    GitRepositoryService.new(scan.project.repository_url).with_cloned_repo do |repo_path|
      # Create zip of the repository
      zip_path = File.join(Dir.tmpdir, "repo_#{scan.id}.zip")

      begin
        Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
          Dir[File.join(repo_path, "**", "*")].each do |file|
            next if File.directory?(file)
            next if file.include?(".git")

            relative_path = file.sub("#{repo_path}/", "")
            zipfile.add(relative_path, file)
          end
        end

        client.upload_file(file_path: zip_path, filename: "repository.zip")
      ensure
        FileUtils.rm_f(zip_path)
      end
    end
  end

  def upload_sbom_content
    Tempfile.create(["sbom", ".json"]) do |temp_file|
      temp_file.write(scan.sbom_content.to_json)
      temp_file.rewind
      client.upload_file(file_path: temp_file.path, filename: "sbom.json")
    end
  end

  def request_inspection(upload_path)
    client.request_inspect(path: upload_path, type: :all)
  end

  def wait_for_completion(task_id)
    attempts = 0

    loop do
      attempts += 1

      if attempts > MAX_POLL_ATTEMPTS
        raise SbomEngineClient::ApiError, "Inspection timed out after #{MAX_POLL_ATTEMPTS * POLL_INTERVAL} seconds"
      end

      progress = client.inspect_progress(task_id: task_id)

      Rails.logger.info("Scan progress for task #{task_id}: #{progress.inspect}")

      # Check if inspection is complete
      if progress_complete?(progress)
        break
      end

      sleep(POLL_INTERVAL)
    end
  end

  def progress_complete?(progress)
    # Assuming progress returns a status or percentage
    return true if progress.is_a?(Hash) && progress["status"] == "completed"
    return true if progress.is_a?(Hash) && progress["progress"] == 100
    return true if progress == "completed"
    false
  end

  def process_results(task_id)
    sbom_type = client.normalize_sbom_format(scan.sbom_format || "cyclonedx")

    result = client.inspect_result(
      task_id: task_id,
      sbom_type: sbom_type,
      get_type: "buffer"
    )

    # Process SBOM data
    if result["sbom"].present?
      process_sbom_data(result["sbom"])
    end

    # Process vulnerability data
    if result["vulnerabilities"].present? || result["vuln"].present?
      save_vulnerabilities_from_result(result)
    end
  end

  def process_sbom_data(sbom_data)
    # Save SBOM content
    scan.update!(sbom_content: sbom_data)

    # Extract and save dependencies
    dependencies = extract_dependencies_from_sbom(sbom_data)
    save_dependencies(dependencies)

    # Determine ecosystem from components
    ecosystems = dependencies.map { |d| d[:ecosystem] }.compact.uniq
    scan.update!(ecosystem: ecosystems.join(",")) if ecosystems.any?
  end

  def extract_dependencies_from_sbom(sbom_data)
    dependencies = []

    # Handle CycloneDX format
    if sbom_data["components"].present?
      sbom_data["components"].each do |component|
        dependencies << {
          name: component["name"],
          version: component["version"],
          ecosystem: extract_ecosystem_from_purl(component["purl"]),
          purl: component["purl"],
          license: extract_license(component)
        }
      end
    end

    # Handle SPDX format
    if sbom_data["packages"].present?
      sbom_data["packages"].each do |package|
        next if package["SPDXID"] == "SPDXRef-DOCUMENT"

        purl = package.dig("externalRefs")&.find { |ref| ref["referenceType"] == "purl" }&.dig("referenceLocator")

        dependencies << {
          name: package["name"],
          version: package["versionInfo"],
          ecosystem: extract_ecosystem_from_purl(purl),
          purl: purl,
          license: package["licenseConcluded"]
        }
      end
    end

    dependencies.uniq { |d| [d[:name], d[:version], d[:ecosystem]] }
  end

  def extract_ecosystem_from_purl(purl)
    return nil unless purl.present?

    # PURL format: pkg:type/namespace/name@version
    match = purl.match(/^pkg:([^\/]+)/)
    return nil unless match

    case match[1]
    when "npm" then "npm"
    when "pypi" then "pip"
    when "maven" then "maven"
    when "gem" then "gem"
    when "cargo" then "cargo"
    when "golang" then "go"
    when "nuget" then "nuget"
    when "composer" then "composer"
    else match[1]
    end
  end

  def extract_license(component)
    if component["licenses"].present?
      component["licenses"].map do |license|
        license.dig("license", "id") || license.dig("license", "name")
      end.compact.join(", ")
    end
  end

  def save_dependencies(dependencies)
    dependencies.each do |dep|
      scan.dependencies.find_or_create_by!(
        name: dep[:name],
        version: dep[:version]
      ) do |d|
        d.ecosystem = dep[:ecosystem]
        d.purl = dep[:purl]
        d.license = dep[:license]
      end
    end
  end

  def save_vulnerabilities_from_result(result)
    vulnerabilities = result["vulnerabilities"] || result["vuln"] || []

    vulnerabilities.each do |vuln|
      save_vulnerability(vuln)
    end
  end

  def save_vulnerability(vuln)
    # Normalize vulnerability data from SBOM Engine format
    scan.vulnerabilities.find_or_create_by!(cve_id: vuln["id"] || vuln["cve_id"]) do |v|
      v.severity = normalize_severity(vuln["severity"] || vuln.dig("cvss", "baseSeverity"))
      v.package_name = vuln["package_name"] || vuln.dig("affected", 0, "package", "name")
      v.package_version = vuln["package_version"] || vuln.dig("affected", 0, "versions", 0)
      v.title = vuln["title"] || vuln["summary"]
      v.description = vuln["description"] || vuln.dig("descriptions", "en")
      v.fixed_version = vuln["fixed_version"] || vuln.dig("affected", 0, "fixed")
      v.cvss_score = vuln["cvss_score"] || vuln.dig("cvss", "baseScore") || vuln.dig("cvssv31", 0, "cvssData", "baseScore")
      v.references = extract_references(vuln)
    end
  end

  def normalize_severity(severity)
    return "UNKNOWN" unless severity.present?

    case severity.to_s.upcase
    when "CRITICAL" then "CRITICAL"
    when "HIGH" then "HIGH"
    when "MEDIUM" then "MEDIUM"
    when "LOW" then "LOW"
    else "UNKNOWN"
    end
  end

  def extract_references(vuln)
    refs = vuln["references"] || []
    refs.map { |ref| ref.is_a?(Hash) ? ref["url"] : ref }.compact
  end
end
