class ReportGeneratorJob < ApplicationJob
  queue_as :default

  def perform(report_id)
    report = Report.find(report_id)
    ReportGeneratorService.new(report: report).generate
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("[ReportGeneratorJob] Report not found: #{report_id}")
  rescue StandardError => e
    Rails.logger.error("[ReportGeneratorJob] Failed: #{e.message}")
    raise
  end
end
