module Api
  module V1
    class VulnerabilitiesController < ApplicationController
      before_action :authenticate_user!
      skip_before_action :verify_authenticity_token

      # GET /api/v1/vulnerabilities/cve
      # Query CVE information from SBOM Engine
      def cve
        result = sbom_client.get_cve(
          id: params[:id],
          page: params[:page] || 1,
          size: params[:size] || 20,
          include_cwe: params[:include_cwe] == "true",
          from_published_date: params[:from_published_date],
          to_published_date: params[:to_published_date]
        )

        render json: { status: true, data: result["data"], counts: result["counts"] }
      rescue SbomEngineClient::ApiError => e
        render json: { status: false, message: e.message }, status: :bad_request
      rescue SbomEngineClient::ConnectionError => e
        render json: { status: false, message: "SBOM Engine not available" }, status: :service_unavailable
      end

      # GET /api/v1/vulnerabilities/cwe
      def cwe
        result = sbom_client.get_cwe(
          id: params[:id],
          page: params[:page] || 1,
          size: params[:size] || 20,
          include_capec: params[:include_capec] == "true"
        )

        render json: { status: true, data: result["data"], counts: result["counts"] }
      rescue SbomEngineClient::ApiError => e
        render json: { status: false, message: e.message }, status: :bad_request
      rescue SbomEngineClient::ConnectionError => e
        render json: { status: false, message: "SBOM Engine not available" }, status: :service_unavailable
      end

      # GET /api/v1/vulnerabilities/ghsa
      def ghsa
        result = sbom_client.get_ghsa(
          id: params[:id],
          page: params[:page] || 1,
          size: params[:size] || 20,
          include_cve: params[:include_cve] == "true"
        )

        render json: { status: true, data: result["data"], counts: result["counts"] }
      rescue SbomEngineClient::ApiError => e
        render json: { status: false, message: e.message }, status: :bad_request
      rescue SbomEngineClient::ConnectionError => e
        render json: { status: false, message: "SBOM Engine not available" }, status: :service_unavailable
      end

      # GET /api/v1/vulnerabilities/kev
      def kev
        result = sbom_client.get_kev(
          id: params[:id],
          page: params[:page] || 1,
          size: params[:size] || 20
        )

        render json: { status: true, data: result["data"], counts: result["counts"] }
      rescue SbomEngineClient::ApiError => e
        render json: { status: false, message: e.message }, status: :bad_request
      rescue SbomEngineClient::ConnectionError => e
        render json: { status: false, message: "SBOM Engine not available" }, status: :service_unavailable
      end

      # GET /api/v1/vulnerabilities/osv
      def osv
        result = sbom_client.get_osv(
          id: params[:id],
          page: params[:page] || 1,
          size: params[:size] || 20
        )

        render json: { status: true, data: result["data"], counts: result["counts"] }
      rescue SbomEngineClient::ApiError => e
        render json: { status: false, message: e.message }, status: :bad_request
      rescue SbomEngineClient::ConnectionError => e
        render json: { status: false, message: "SBOM Engine not available" }, status: :service_unavailable
      end

      # GET /api/v1/vulnerabilities/search
      # Search for vulnerabilities by package name
      def search
        unless params[:package_name].present?
          render json: { status: false, message: "package_name is required" }, status: :bad_request
          return
        end

        result = sbom_client.get_software(
          name: params[:package_name],
          type: params[:ecosystem],
          page: params[:page] || 1,
          size: params[:size] || 20
        )

        render json: { status: true, data: result["data"], counts: result["counts"] }
      rescue SbomEngineClient::ApiError => e
        render json: { status: false, message: e.message }, status: :bad_request
      rescue SbomEngineClient::ConnectionError => e
        render json: { status: false, message: "SBOM Engine not available" }, status: :service_unavailable
      end

      private

      def sbom_client
        @sbom_client ||= SbomEngineClient.new
      end
    end
  end
end
