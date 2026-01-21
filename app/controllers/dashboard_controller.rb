class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @projects = current_user.projects.includes(:scans).limit(5)
    @recent_scans = current_user.scans.includes(:project, :vulnerabilities).recent.limit(10)
    @vulnerability_stats = calculate_vulnerability_stats
    @vulnerability_trends = calculate_vulnerability_trends
    @total_projects = current_user.projects.count
    @total_scans = current_user.scans.count
    @total_vulnerabilities = current_user.vulnerabilities.count
  end

  private

  def calculate_vulnerability_stats
    vulnerabilities = current_user.vulnerabilities

    {
      critical: vulnerabilities.critical.count,
      high: vulnerabilities.high.count,
      medium: vulnerabilities.medium.count,
      low: vulnerabilities.low.count,
      total: vulnerabilities.count
    }
  end

  def calculate_vulnerability_trends
    current_user.scans
      .completed
      .includes(:vulnerabilities)
      .order(created_at: :asc)
      .limit(10)
      .map do |scan|
        {
          date: (scan.scanned_at || scan.created_at).iso8601,
          total: scan.vulnerabilities.count,
          critical: scan.vulnerabilities.critical.count,
          high: scan.vulnerabilities.high.count,
          medium: scan.vulnerabilities.medium.count,
          low: scan.vulnerabilities.low.count
        }
      end
  end
end
