# SBOM Engine API Client
# Connects to SBOM Engine backend for scanning and vulnerability queries
class SbomEngineClient
  include HTTParty

  class ApiError < StandardError; end
  class ConnectionError < ApiError; end
  class InspectError < ApiError; end

  SBOM_FORMATS = {
    "cyclonedx-json-1.4" => "cyclonedx-json@1.4",
    "cyclonedx-json-1.5" => "cyclonedx-json@1.5",
    "cyclonedx-json-1.6" => "cyclonedx-json@1.6",
    "spdx-json-2.3" => "spdx-json@2.3",
    "cyclonedx" => "cyclonedx-json@1.5",
    "spdx" => "spdx-json@2.3"
  }.freeze

  INSPECT_TYPES = {
    all: "all",       # SW scan + vulnerability analysis
    scan: "scan",     # SW scan only
    check: "check",   # Vulnerability analysis only
    correct: "correct", # SBOM document correction
    convert: "convert"  # SBOM format conversion
  }.freeze

  def initialize
    @base_url = Rails.configuration.sbom_engine[:base_url]
    @timeout = Rails.configuration.sbom_engine[:timeout] || 30
  end

  # Check if SBOM Engine is available for inspection
  def available?
    response = self.class.get(
      "#{@base_url}/api/v1/inspect/available",
      headers: default_headers,
      timeout: @timeout
    )

    if response.success?
      parsed = JSON.parse(response.body)
      parsed["status"] == true
    else
      false
    end
  rescue StandardError => e
    Rails.logger.error("SBOM Engine availability check failed: #{e.message}")
    false
  end

  # Upload software file for inspection
  # Returns the path for subsequent inspect call
  def upload_file(file_path:, filename: nil)
    filename ||= File.basename(file_path)

    response = self.class.post(
      "#{@base_url}/api/v1/upload",
      multipart: true,
      body: {
        sw: File.open(file_path)
      },
      timeout: @timeout * 3 # Allow more time for uploads
    )

    handle_response(response) do |data|
      data["path"]
    end
  end

  # Upload file from ActiveStorage attachment
  def upload_attachment(attachment)
    Tempfile.create([attachment.filename.base, attachment.filename.extension_with_delimiter]) do |temp_file|
      temp_file.binmode
      temp_file.write(attachment.download)
      temp_file.rewind
      upload_file(file_path: temp_file.path, filename: attachment.filename.to_s)
    end
  end

  # Request software inspection
  # type: all, scan, check, correct, convert
  # Returns task_id for progress and result queries
  def request_inspect(path:, type: :all)
    inspect_type = INSPECT_TYPES[type.to_sym] || "all"

    response = self.class.post(
      "#{@base_url}/api/v1/inspect",
      headers: default_headers,
      body: {
        path: path,
        type: inspect_type
      }.to_json,
      timeout: @timeout
    )

    handle_response(response) do |data|
      data # Returns task_id
    end
  end

  # Check inspection progress
  def inspect_progress(task_id:)
    response = self.class.get(
      "#{@base_url}/api/v1/inspect/progress",
      query: { id: task_id },
      headers: default_headers,
      timeout: @timeout
    )

    handle_response(response) do |data|
      data # Returns progress info
    end
  end

  # Get inspection result with SBOM and vulnerabilities
  def inspect_result(task_id:, sbom_type: "cyclonedx-json@1.5", get_type: "buffer")
    response = self.class.get(
      "#{@base_url}/api/v1/inspect/result",
      query: {
        id: task_id,
        sbomType: sbom_type,
        getType: get_type
      },
      headers: default_headers,
      timeout: @timeout * 2
    )

    handle_response(response) do |data|
      data # Returns SBOM and vulnerability data
    end
  end

  # Get CVE vulnerability information
  def get_cve(id: nil, page: 1, size: 20, include_cwe: false, **filters)
    query = build_vuln_query(page: page, size: size, **filters)
    query[:id] = id if id.present?
    query[:include] = "cwe" if include_cwe

    response = self.class.get(
      "#{@base_url}/api/v1/vuln/cve",
      query: query,
      headers: default_headers,
      timeout: @timeout
    )

    handle_response(response)
  end

  # Get CWE vulnerability information
  def get_cwe(id: nil, page: 1, size: 20, include_capec: false, **filters)
    query = build_vuln_query(page: page, size: size, **filters)
    query[:id] = id if id.present?
    query[:include] = "capec" if include_capec

    response = self.class.get(
      "#{@base_url}/api/v1/vuln/cwe",
      query: query,
      headers: default_headers,
      timeout: @timeout
    )

    handle_response(response)
  end

  # Get GHSA vulnerability information
  def get_ghsa(id: nil, page: 1, size: 20, include_cve: false, **filters)
    query = build_vuln_query(page: page, size: size, **filters)
    query[:id] = id if id.present?
    query[:include] = "cve" if include_cve

    response = self.class.get(
      "#{@base_url}/api/v1/vuln/ghsa",
      query: query,
      headers: default_headers,
      timeout: @timeout
    )

    handle_response(response)
  end

  # Get KEV (Known Exploited Vulnerabilities) information
  def get_kev(id: nil, page: 1, size: 20, **filters)
    query = build_vuln_query(page: page, size: size, **filters)
    query[:id] = id if id.present?

    response = self.class.get(
      "#{@base_url}/api/v1/vuln/kev",
      query: query,
      headers: default_headers,
      timeout: @timeout
    )

    handle_response(response)
  end

  # Get OSV vulnerability information
  def get_osv(id: nil, page: 1, size: 20, **filters)
    query = build_vuln_query(page: page, size: size, **filters)
    query[:id] = id if id.present?

    response = self.class.get(
      "#{@base_url}/api/v1/vuln/osv",
      query: query,
      headers: default_headers,
      timeout: @timeout
    )

    handle_response(response)
  end

  # Get license information
  def get_license(id: nil, page: 1, size: 20)
    query = { page: page, size: size }
    query[:id] = id if id.present?

    response = self.class.get(
      "#{@base_url}/api/v1/vuln/license",
      query: query,
      headers: default_headers,
      timeout: @timeout
    )

    handle_response(response)
  end

  # Get software/package information
  def get_software(name: nil, type: nil, page: 1, size: 20, **filters)
    query = { page: page, size: size }
    query[:name] = name if name.present?
    query[:type] = type if type.present?
    add_date_filters(query, filters)

    response = self.class.get(
      "#{@base_url}/api/v1/sw",
      query: query,
      headers: default_headers,
      timeout: @timeout
    )

    handle_response(response)
  end

  # Normalize SBOM format string to API expected format
  def normalize_sbom_format(format)
    SBOM_FORMATS[format.to_s.downcase] || "cyclonedx-json@1.5"
  end

  private

  def default_headers
    {
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }
  end

  def handle_response(response)
    case response.code
    when 200
      parsed = JSON.parse(response.body)
      if parsed["status"] == true
        block_given? ? yield(parsed["data"]) : parsed
      else
        raise ApiError, parsed["message"] || "API request failed"
      end
    when 400
      raise ApiError, "Bad request: #{extract_error_message(response)}"
    when 404
      raise ApiError, "Resource not found: #{extract_error_message(response)}"
    when 500
      raise ApiError, "Server error: #{extract_error_message(response)}"
    when 503
      raise ConnectionError, "SBOM Engine is currently unavailable"
    else
      raise ApiError, "Unexpected response: #{response.code}"
    end
  rescue JSON::ParserError => e
    raise ApiError, "Invalid JSON response: #{e.message}"
  rescue Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout => e
    raise ConnectionError, "Failed to connect to SBOM Engine: #{e.message}"
  end

  def extract_error_message(response)
    parsed = JSON.parse(response.body)
    parsed["message"] || "Unknown error"
  rescue JSON::ParserError
    response.body
  end

  def build_vuln_query(page:, size:, **filters)
    query = { page: page, size: size }
    add_date_filters(query, filters)
    query
  end

  def add_date_filters(query, filters)
    query[:fromPublishedDate] = filters[:from_published_date] if filters[:from_published_date]
    query[:toPublishedDate] = filters[:to_published_date] if filters[:to_published_date]
    query[:fromCreatedDate] = filters[:from_created_date] if filters[:from_created_date]
    query[:toCreatedDate] = filters[:to_created_date] if filters[:to_created_date]
    query[:fromUpdatedDate] = filters[:from_updated_date] if filters[:from_updated_date]
    query[:toUpdatedDate] = filters[:to_updated_date] if filters[:to_updated_date]
  end
end
