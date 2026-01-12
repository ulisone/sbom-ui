class VulnerabilitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vulnerability, only: [:show]

  def index
    @vulnerabilities = current_user.vulnerabilities
                                   .includes(scan: :project)
                                   .by_severity

    # Filter by severity if provided
    if params[:severity].present?
      @vulnerabilities = @vulnerabilities.where(severity: params[:severity].upcase)
    end

    # Filter by project if provided
    if params[:project_id].present?
      @vulnerabilities = @vulnerabilities.joins(scan: :project)
                                         .where(projects: { id: params[:project_id] })
    end

    @severity_counts = current_user.vulnerabilities.group(:severity).count
  end

  def show
  end

  private

  def set_vulnerability
    @vulnerability = current_user.vulnerabilities.find(params[:id])
  end
end
