module Api
  module V1
    class SbomEngineController < ApplicationController
      before_action :authenticate_user!
      skip_before_action :verify_authenticity_token

      # GET /api/v1/sbom_engine/status
      # Check SBOM Engine availability
      def status
        available = sbom_client.available?

        render json: {
          status: true,
          available: available,
          base_url: Rails.configuration.sbom_engine[:base_url]
        }
      rescue SbomEngineClient::ConnectionError => e
        render json: {
          status: true,
          available: false,
          message: e.message
        }
      end

      # POST /api/v1/sbom_engine/inspect
      # Request manual inspection
      def inspect
        unless params[:file].present? || params[:path].present?
          render json: { status: false, message: "file or path is required" }, status: :bad_request
          return
        end

        # Upload file if provided
        if params[:file].present?
          path = upload_file(params[:file])
        else
          path = params[:path]
        end

        # Request inspection
        task_id = sbom_client.request_inspect(
          path: path,
          type: params[:inspect_type]&.to_sym || :all
        )

        render json: { status: true, task_id: task_id }
      rescue SbomEngineClient::ApiError => e
        render json: { status: false, message: e.message }, status: :bad_request
      rescue SbomEngineClient::ConnectionError => e
        render json: { status: false, message: "SBOM Engine not available" }, status: :service_unavailable
      end

      # GET /api/v1/sbom_engine/progress/:task_id
      # Check inspection progress
      def progress
        unless params[:task_id].present?
          render json: { status: false, message: "task_id is required" }, status: :bad_request
          return
        end

        progress = sbom_client.inspect_progress(task_id: params[:task_id])

        render json: { status: true, progress: progress }
      rescue SbomEngineClient::ApiError => e
        render json: { status: false, message: e.message }, status: :bad_request
      rescue SbomEngineClient::ConnectionError => e
        render json: { status: false, message: "SBOM Engine not available" }, status: :service_unavailable
      end

      # GET /api/v1/sbom_engine/result/:task_id
      # Get inspection result
      def result
        unless params[:task_id].present?
          render json: { status: false, message: "task_id is required" }, status: :bad_request
          return
        end

        sbom_type = params[:sbom_type] || "cyclonedx-json@1.5"

        result = sbom_client.inspect_result(
          task_id: params[:task_id],
          sbom_type: sbom_type,
          get_type: params[:get_type] || "buffer"
        )

        render json: { status: true, data: result }
      rescue SbomEngineClient::ApiError => e
        render json: { status: false, message: e.message }, status: :bad_request
      rescue SbomEngineClient::ConnectionError => e
        render json: { status: false, message: "SBOM Engine not available" }, status: :service_unavailable
      end

      private

      def sbom_client
        @sbom_client ||= SbomEngineClient.new
      end

      def upload_file(file)
        Tempfile.create([file.original_filename, File.extname(file.original_filename)]) do |temp_file|
          temp_file.binmode
          temp_file.write(file.read)
          temp_file.rewind
          sbom_client.upload_file(file_path: temp_file.path, filename: file.original_filename)
        end
      end
    end
  end
end
