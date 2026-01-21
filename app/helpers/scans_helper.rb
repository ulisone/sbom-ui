module ScansHelper
  def dependency_tree_data(scan)
    DependencyTreeService.new(scan: scan).build_tree
  end

  def vulnerability_severity_data(scan)
    return {} unless scan
    {
      critical: scan.vulnerabilities.critical.count,
      high: scan.vulnerabilities.high.count,
      medium: scan.vulnerabilities.medium.count,
      low: scan.vulnerabilities.low.count
    }
  end

  def vulnerability_trend_data(project, limit: 10)
    project.scans.completed.order(created_at: :asc).limit(limit).map do |s|
      {
        date: s.scanned_at || s.created_at,
        total: s.vulnerabilities.count,
        critical: s.vulnerabilities.critical.count,
        high: s.vulnerabilities.high.count,
        medium: s.vulnerabilities.medium.count,
        low: s.vulnerabilities.low.count
      }
    end
  end
end
