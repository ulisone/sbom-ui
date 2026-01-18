require 'net/http'
require 'openssl'
require 'json'
require 'uri'

module Clients
  class SbomEngineClient
    class Error < StandardError; end
    class ApiError < Error; end
    class TimeoutError < Error; end

    DEFAULT_BASE_URL = "https://localhost:5699/api/v1"
    # Secret key matching the Go backend (SCSAEZIZ_yeori_wedsaq123)
    SECRET_KEY = "SCSAEZIZ_yeori_wedsaq123"
    USER_ID = "yeori"

    def initialize(base_url: nil)
      @base_url = base_url || ENV.fetch("SBOM_ENGINE_URL", DEFAULT_BASE_URL)
    end

    def upload_file(file_path)
      uri = URI.parse("#{@base_url}/upload")
      request = Net::HTTP::Post.new(uri)
      
      # Set multipart form data
      file = File.open(file_path)
      form_data = [['sw', file]]
      request.set_form(form_data, 'multipart/form-data')
      
      response = send_request(uri, request)
      
      unless response.is_a?(Net::HTTPSuccess)
        raise ApiError, "Upload failed: #{response.code} #{response.message} - #{response.body}"
      end

      json = JSON.parse(response.body)
      validate_response!(json)
      
      # The API returns path with 'uploads/' prefix potentially, 
      # but inspect requires the path relative to upload root usually.
      # Manual script uses: sed 's/^uploads\///'
      path = json.dig("data", "path")
      path&.sub(/^uploads\//, '')
    ensure
      file&.close
    end

    def request_inspect(remote_path, type: "all")
      uri = URI.parse("#{@base_url}/inspect")
      request = Net::HTTP::Post.new(uri)
      request.content_type = 'application/json'
      request.body = { path: remote_path, type: type }.to_json

      response = send_request(uri, request)
      
      unless response.is_a?(Net::HTTPSuccess)
        raise ApiError, "Inspect request failed: #{response.code} #{response.body}"
      end

      json = JSON.parse(response.body)
      validate_response!(json)
      
      id = json.dig("data", "id")
      Rails.logger.debug "[SbomEngineClient] Inspect Task ID: #{id} (Response: #{response.body})"
      id
    end

    def check_progress(task_id)
      uri = URI.parse("#{@base_url}/inspect/progress/#{task_id}")
      request = Net::HTTP::Get.new(uri)

      response = send_request(uri, request)
      
      unless response.is_a?(Net::HTTPSuccess)
        raise ApiError, "Progress check failed: #{response.code} #{response.body}"
      end

      json = JSON.parse(response.body)
      validate_response!(json)
      
      # data is an array based on manual
      status_data = json["data"]&.first
      return nil unless status_data

      status_data["status"]
    end

    def get_result(task_id, sbom_format: "cyclonedx-json@1.6")
      uri = URI.parse("#{@base_url}/inspect/result/#{task_id}")
      query_params = URI.encode_www_form(
        sbomType: sbom_format,
        getType: "buffer"
      )
      uri.query = query_params
      
      request = Net::HTTP::Get.new(uri)

      response = send_request(uri, request)
      
      unless response.is_a?(Net::HTTPSuccess)
        raise ApiError, "Get result failed: #{response.code} #{response.body}"
      end

      json = JSON.parse(response.body)
      validate_response!(json)
      
      json["data"]
    end

    private

    STATIC_TOKEN = "yeori:1737016845:c69ecea0e27c519e23af174a2e9fcae4a7fa947a3e6e5e0dab31496521f94d66"

    def send_request(uri, request)
      token = STATIC_TOKEN 
      request["Authorization"] = token
      Rails.logger.debug "[SbomEngineClient] Request to #{uri} with Token: #{token}"

      http = Net::HTTP.new(uri.host, uri.port)
      
      if uri.scheme == "https"
        http.use_ssl = true
        # For development with self-signed certs
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      http.request(request)
    end

    def generate_token
      timestamp = Time.now.to_i
      payload = "#{USER_ID}:#{timestamp}"
      
      # HMAC-SHA256 signature
      digest = OpenSSL::Digest.new('sha256')
      signature = OpenSSL::HMAC.hexdigest(digest, SECRET_KEY, payload)
      
      "#{payload}:#{signature}"
    end

    def validate_response!(json)
      if json["status"] == false || (json["code"] != 0 && json["code"] != nil)
        raise ApiError, "API Error #{json['code']}: #{json['message']}"
      end
    end
  end
end
