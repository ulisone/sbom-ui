module Scanners
  class SbomEngineScanner
    POLL_INTERVAL = 3
    MAX_RETRIES = 100 # Approx 5 minutes

    attr_reader :scan, :client

    def initialize(scan)
      @scan = scan
      @client = Clients::SbomEngineClient.new
    end

    def perform
      # Currently only supports single file scanning efficiently via this flow
      # We'll take the first file attached to the scan
      file = scan.dependency_files.first
      raise StandardError, "No dependency file attached" unless file

      # Create temp file for upload
      file.open do |temp_file|
        # 1. Upload
        Rails.logger.info("Uploading file #{file.filename} to SBOM Engine...")
        remote_path = client.upload_file(temp_file.path)
        
        # 2. Request Inspect
        Rails.logger.info("Requesting inspection for #{remote_path}...")
        task_id = client.request_inspect(remote_path, type: "all")
        
        # 3. Poll Progress
        wait_for_completion(task_id)

        # 4. Get Result
        Rails.logger.info("Fetching results for task #{task_id}...")
        result_data = client.get_result(task_id, sbom_format: format_mapping(scan.sbom_format))

        return result_data
      end
    end

    private

    def wait_for_completion(task_id)
      MAX_RETRIES.times do |i|
        begin
          status = client.check_progress(task_id)
          Rails.logger.debug("Scan task #{task_id} status: #{status}")

          case status
          when "task complete."
            return true
          when /error/i
            raise StandardError, "SBOM Engine Scan Failed: #{status}"
          end
        rescue Clients::SbomEngineClient::ApiError => e
          if e.message.include?("404") || e.message.include?("Resource not found")
            Rails.logger.info("Task #{task_id} not initialized yet, retrying...")
          else
            raise e
          end
        end

        sleep POLL_INTERVAL
      end
      
      raise StandardError, "Scan timed out after #{MAX_RETRIES * POLL_INTERVAL} seconds"
    end

    def format_mapping(format)
      case format
      when "cyclonedx" then "cyclonedx-json@1.6"
      when "spdx" then "spdx-json@2.3"
      else "cyclonedx-json@1.6"
      end
    end
  end
end
