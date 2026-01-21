class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [:new, :create]
  before_action :set_report, only: [:show, :download, :destroy]

  def index
    @reports = current_user.reports
                           .includes(:project, :scan)
                           .recent
                           .page(params[:page])
                           .per(20)
  end

  def show
    @vulnerabilities = @report.scan&.vulnerabilities&.by_severity || []
    @dependencies = @report.scan&.dependencies&.order(:name) || []
  end

  def new
    @report = @project.reports.build
    @scans = @project.scans.completed.recent.limit(10)
  end

  def create
    @report = @project.reports.build(report_params)
    @report.status = :pending

    if @report.save
      ReportGeneratorJob.perform_later(@report.id)
      redirect_to @report, notice: t("reports.messages.generating")
    else
      @scans = @project.scans.completed.recent.limit(10)
      render :new, status: :unprocessable_entity
    end
  end

  def download
    if @report.file.attached?
      redirect_to rails_blob_path(@report.file, disposition: "attachment")
    elsif @report.format == "html"
      # Generate HTML download on the fly
      send_data render_to_string(partial: "reports/export_html", locals: { report: @report }),
                filename: "#{@report.title.parameterize}.html",
                type: "text/html"
    elsif @report.format == "json"
      send_data @report.content.to_json,
                filename: "#{@report.title.parameterize}.json",
                type: "application/json"
    else
      redirect_to @report, alert: t("reports.messages.download_not_available")
    end
  end

  def destroy
    project = @report.project
    @report.destroy
    redirect_to project_path(project), notice: t("reports.messages.deleted")
  end

  # Quick report generation endpoints
  def generate_summary_report
    project = current_user.projects.find(params[:id])
    scan = project.scans.completed.recent.first

    unless scan
      redirect_to project, alert: t("reports.messages.no_scan_available")
      return
    end

    report = project.reports.create!(
      report_type: "summary",
      format: params[:format] || "html",
      scan: scan,
      status: :pending
    )

    ReportGeneratorJob.perform_later(report.id)
    redirect_to report, notice: t("reports.messages.generating")
  end

  def generate_detailed_report
    project = current_user.projects.find(params[:id])
    scan = project.scans.completed.recent.first

    unless scan
      redirect_to project, alert: t("reports.messages.no_scan_available")
      return
    end

    report = project.reports.create!(
      report_type: "detailed",
      format: params[:format] || "html",
      scan: scan,
      status: :pending
    )

    ReportGeneratorJob.perform_later(report.id)
    redirect_to report, notice: t("reports.messages.generating")
  end

  def generate_executive_report
    project = current_user.projects.find(params[:id])
    scan = project.scans.completed.recent.first

    unless scan
      redirect_to project, alert: t("reports.messages.no_scan_available")
      return
    end

    report = project.reports.create!(
      report_type: "executive",
      format: params[:format] || "html",
      scan: scan,
      status: :pending
    )

    ReportGeneratorJob.perform_later(report.id)
    redirect_to report, notice: t("reports.messages.generating")
  end

  def generate_trend_report
    project = current_user.projects.find(params[:id])

    if project.scans.completed.count < 2
      redirect_to project, alert: t("reports.messages.insufficient_scans")
      return
    end

    report = project.reports.create!(
      report_type: "trend",
      format: params[:format] || "html",
      status: :pending
    )

    ReportGeneratorJob.perform_later(report.id)
    redirect_to report, notice: t("reports.messages.generating")
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_report
    @report = current_user.reports.find(params[:id])
  end

  def report_params
    params.require(:report).permit(:report_type, :format, :scan_id, :title, :description)
  end
end
