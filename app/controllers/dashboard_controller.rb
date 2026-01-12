class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @projects = current_user.projects.includes(:scans).limit(5)
    @recent_scans = current_user.scans.includes(:project, :vulnerabilities).recent.limit(10)
    @vulnerability_stats = calculate_vulnerability_stats
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
end
