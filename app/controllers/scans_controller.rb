class ScansController < ApplicationController
  before_action :authenticate_user!
  before_action :set_scan, only: [:show, :status, :download_sbom, :rescan]
  before_action :set_project, only: [:new, :create]

  def index
    @scans = current_user.scans
                         .includes(:project, :vulnerabilities)
                         .recent
                         .page(params[:page])
                         .per(20)
  end

  def show
    @vulnerabilities = @scan.vulnerabilities.by_severity
    @dependencies = @scan.dependencies.order(:name)
  end

  def new
    @scan = @project.scans.build
  end

  def create
    @scan = @project.scans.build(scan_params)
    @scan.status = :pending

    # Check if we should scan from Git repo or uploaded files
    if params[:scan_source] == "repository"
      if @project.repository_url.blank?
        @scan.errors.add(:base, "No repository URL configured for this project")
        render :new, status: :unprocessable_entity
        return
      end

      if @scan.save
        GitScanJob.perform_later(@scan.id)
        redirect_to @scan, notice: "Git repository scan started. Results will be available shortly."
      else
        render :new, status: :unprocessable_entity
      end
    elsif scan_params[:dependency_files].present?
      if @scan.save
        ScanJob.perform_later(@scan.id)
        redirect_to @scan, notice: "Scan started. Results will be available shortly."
      else
        render :new, status: :unprocessable_entity
      end
    else
      @scan.errors.add(:base, "Please upload files or scan from repository")
      render :new, status: :unprocessable_entity
    end
  end

  def status
    render json: {
      status: @scan.status,
      vulnerabilities_count: @scan.total_vulnerabilities,
      completed: @scan.completed?
    }
  end

  def download_sbom
    if @scan.sbom_content.present?
      send_data(
        @scan.sbom_content.to_json,
        filename: "#{@scan.project.name.parameterize}-sbom.json",
        type: "application/json"
      )
    else
      redirect_to @scan, alert: "SBOM not available yet."
    end
  end

  def rescan
    if @scan.sbom_content.blank?
      redirect_to @scan, alert: "Cannot rescan: No SBOM data available."
      return
    end

    # Create a new scan based on the previous one
    new_scan = @scan.project.scans.create!(
      status: :pending,
      sbom_format: @scan.sbom_format,
      ecosystem: @scan.ecosystem
    )

    # Copy dependencies from the original scan
    @scan.dependencies.each do |dep|
      new_scan.dependencies.create!(
        name: dep.name,
        version: dep.version,
        ecosystem: dep.ecosystem,
        purl: dep.purl,
        license: dep.license
      )
    end

    # Copy SBOM content
    new_scan.update!(sbom_content: @scan.sbom_content)

    # Run vulnerability scan only
    RescanJob.perform_later(new_scan.id)

    redirect_to new_scan, notice: "Re-scanning vulnerabilities. Results will be available shortly."
  end

  private

  def set_scan
    @scan = current_user.scans.find(params[:id])
  end

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def scan_params
    params.require(:scan).permit(:sbom_format, dependency_files: [])
  end
end
