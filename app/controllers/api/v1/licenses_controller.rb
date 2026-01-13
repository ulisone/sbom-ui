module Api
  module V1
    class LicensesController < ApplicationController
      before_action :authenticate_user!
      skip_before_action :verify_authenticity_token

      # GET /api/v1/licenses
      # Query license information from SBOM Engine
      def index
        result = sbom_client.get_license(
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

      private

      def sbom_client
        @sbom_client ||= SbomEngineClient.new
      end
    end
  end
end
