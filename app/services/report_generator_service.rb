# Report Generator Service
# Generates various types of security analysis reports
class ReportGeneratorService
  attr_reader :report, :project, :scan

  def initialize(report:)
    @report = report
    @project = report.project
    @scan = report.scan || project.scans.completed.recent.first
  end

  def generate
    report.update!(status: :generating)

    content = case report.report_type
              when "summary" then generate_summary_report
              when "detailed" then generate_detailed_report
              when "executive" then generate_executive_report
              when "compliance" then generate_compliance_report
              when "trend" then generate_trend_report
              else generate_summary_report
              end

    report.update!(
      status: :completed,
      content: content,
      generated_at: Time.current,
      title: generate_title,
      metadata: generate_metadata
    )

    generate_file_export if report.format != "html"

    report
  rescue StandardError => e
    report.update!(status: :failed)
    Rails.logger.error("[ReportGenerator] Failed: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    raise
  end

  private

  def generate_summary_report
    {
      vulnerability_summary: vulnerability_summary,
      dependency_summary: dependency_summary,
      risk_score: calculate_risk_score,
      top_vulnerabilities: top_vulnerabilities(5),
      recommendations: generate_recommendations,
      scan_info: scan_info
    }
  end

  def generate_detailed_report
    {
      vulnerability_summary: vulnerability_summary,
      dependency_summary: dependency_summary,
      risk_score: calculate_risk_score,
      all_vulnerabilities: all_vulnerabilities,
      all_dependencies: all_dependencies,
      vulnerability_by_package: vulnerabilities_by_package,
      vulnerability_by_ecosystem: vulnerabilities_by_ecosystem,
      recommendations: generate_recommendations,
      remediation_plan: generate_remediation_plan,
      scan_info: scan_info
    }
  end

  def generate_executive_report
    {
      executive_summary: executive_summary,
      risk_score: calculate_risk_score,
      risk_level: risk_level,
      key_findings: key_findings,
      vulnerability_summary: vulnerability_summary,
      trend_summary: trend_summary,
      recommendations: generate_recommendations.first(3),
      compliance_status: compliance_status
    }
  end

  def generate_compliance_report
    {
      vulnerability_summary: vulnerability_summary,
      compliance_checks: compliance_checks,
      policy_violations: policy_violations,
      license_analysis: license_analysis,
      risk_score: calculate_risk_score,
      recommendations: generate_recommendations
    }
  end

  def generate_trend_report
    {
      vulnerability_trends: vulnerability_trends,
      dependency_trends: dependency_trends,
      risk_score_trends: risk_score_trends,
      scan_frequency: scan_frequency,
      improvement_metrics: improvement_metrics
    }
  end

  # === Summary Helpers ===

  def vulnerability_summary
    return {} unless scan

    vulns = scan.vulnerabilities
    {
      total: vulns.count,
      critical: vulns.critical.count,
      high: vulns.high.count,
      medium: vulns.medium.count,
      low: vulns.low.count,
      with_fix: vulns.where.not(fixed_version: [nil, ""]).count,
      without_fix: vulns.where(fixed_version: [nil, ""]).count
    }
  end

  def dependency_summary
    return {} unless scan

    deps = scan.dependencies
    ecosystems = deps.group(:ecosystem).count
    {
      total: deps.count,
      by_ecosystem: ecosystems,
      unique_packages: deps.distinct.count(:name)
    }
  end

  def calculate_risk_score
    return 0 unless scan

    vulns = scan.vulnerabilities
    critical_weight = 10
    high_weight = 5
    medium_weight = 2
    low_weight = 1

    raw_score = (vulns.critical.count * critical_weight) +
                (vulns.high.count * high_weight) +
                (vulns.medium.count * medium_weight) +
                (vulns.low.count * low_weight)

    # Normalize to 0-100 scale
    [raw_score, 100].min
  end

  def risk_level
    score = calculate_risk_score
    case score
    when 0..20 then "low"
    when 21..50 then "medium"
    when 51..80 then "high"
    else "critical"
    end
  end

  def top_vulnerabilities(limit = 5)
    return [] unless scan

    scan.vulnerabilities.by_severity.limit(limit).map do |v|
      {
        cve_id: v.cve_id,
        severity: v.severity,
        package: v.affected_package,
        title: v.title,
        cvss_score: v.cvss_score,
        has_fix: v.has_fix?,
        fixed_version: v.fixed_version
      }
    end
  end

  def all_vulnerabilities
    return [] unless scan

    scan.vulnerabilities.by_severity.map do |v|
      {
        cve_id: v.cve_id,
        severity: v.severity,
        package_name: v.package_name,
        package_version: v.package_version,
        title: v.title,
        description: v.description,
        cvss_score: v.cvss_score,
        has_fix: v.has_fix?,
        fixed_version: v.fixed_version,
        references: v.reference_urls
      }
    end
  end

  def all_dependencies
    return [] unless scan

    scan.dependencies.order(:ecosystem, :name).map do |d|
      {
        name: d.name,
        version: d.version,
        ecosystem: d.ecosystem,
        purl: d.purl,
        license: d.license
      }
    end
  end

  def vulnerabilities_by_package
    return {} unless scan

    scan.vulnerabilities.group_by(&:package_name).transform_values do |vulns|
      {
        count: vulns.size,
        critical: vulns.count { |v| v.severity == "CRITICAL" },
        high: vulns.count { |v| v.severity == "HIGH" },
        medium: vulns.count { |v| v.severity == "MEDIUM" },
        low: vulns.count { |v| v.severity == "LOW" }
      }
    end
  end

  def vulnerabilities_by_ecosystem
    return {} unless scan

    deps_by_ecosystem = scan.dependencies.group_by(&:ecosystem)
    result = {}

    deps_by_ecosystem.each do |ecosystem, deps|
      package_names = deps.map(&:name)
      vulns = scan.vulnerabilities.where(package_name: package_names)
      result[ecosystem] = {
        total_dependencies: deps.size,
        total_vulnerabilities: vulns.count,
        critical: vulns.critical.count,
        high: vulns.high.count,
        medium: vulns.medium.count,
        low: vulns.low.count
      }
    end

    result
  end

  def generate_recommendations
    recommendations = []
    return recommendations unless scan

    vulns = scan.vulnerabilities

    # Critical vulnerabilities recommendation
    if vulns.critical.any?
      recommendations << {
        priority: "critical",
        category: "security",
        title: I18n.t("reports.recommendations.fix_critical"),
        description: I18n.t("reports.recommendations.fix_critical_desc", count: vulns.critical.count),
        packages: vulns.critical.pluck(:package_name).uniq.first(5)
      }
    end

    # High vulnerabilities with fixes
    high_with_fix = vulns.high.where.not(fixed_version: [nil, ""])
    if high_with_fix.any?
      recommendations << {
        priority: "high",
        category: "security",
        title: I18n.t("reports.recommendations.upgrade_packages"),
        description: I18n.t("reports.recommendations.upgrade_packages_desc", count: high_with_fix.count),
        packages: high_with_fix.pluck(:package_name, :fixed_version).uniq.first(5)
      }
    end

    # Vulnerabilities without fixes
    no_fix = vulns.where(fixed_version: [nil, ""]).where(severity: %w[CRITICAL HIGH])
    if no_fix.any?
      recommendations << {
        priority: "medium",
        category: "risk_mitigation",
        title: I18n.t("reports.recommendations.mitigate_no_fix"),
        description: I18n.t("reports.recommendations.mitigate_no_fix_desc", count: no_fix.count),
        packages: no_fix.pluck(:package_name).uniq.first(5)
      }
    end

    # Regular scanning recommendation
    last_scan = project.scans.completed.recent.first
    if last_scan && last_scan.created_at < 7.days.ago
      recommendations << {
        priority: "low",
        category: "process",
        title: I18n.t("reports.recommendations.regular_scan"),
        description: I18n.t("reports.recommendations.regular_scan_desc")
      }
    end

    recommendations
  end

  def generate_remediation_plan
    return [] unless scan

    plan = []
    vulns_by_priority = scan.vulnerabilities.by_severity.group_by(&:severity)

    # Phase 1: Critical
    if vulns_by_priority["CRITICAL"]&.any?
      plan << {
        phase: 1,
        priority: "critical",
        title: I18n.t("reports.remediation.phase_critical"),
        actions: vulns_by_priority["CRITICAL"].map do |v|
          {
            package: v.affected_package,
            action: v.has_fix? ? "upgrade_to_#{v.fixed_version}" : "apply_workaround",
            cve_id: v.cve_id
          }
        end
      }
    end

    # Phase 2: High
    if vulns_by_priority["HIGH"]&.any?
      plan << {
        phase: 2,
        priority: "high",
        title: I18n.t("reports.remediation.phase_high"),
        actions: vulns_by_priority["HIGH"].first(10).map do |v|
          {
            package: v.affected_package,
            action: v.has_fix? ? "upgrade_to_#{v.fixed_version}" : "evaluate_alternatives",
            cve_id: v.cve_id
          }
        end
      }
    end

    # Phase 3: Medium/Low
    medium_low = (vulns_by_priority["MEDIUM"] || []) + (vulns_by_priority["LOW"] || [])
    if medium_low.any?
      plan << {
        phase: 3,
        priority: "medium",
        title: I18n.t("reports.remediation.phase_medium_low"),
        actions: medium_low.first(10).map do |v|
          {
            package: v.affected_package,
            action: v.has_fix? ? "upgrade_to_#{v.fixed_version}" : "monitor",
            cve_id: v.cve_id
          }
        end
      }
    end

    plan
  end

  # === Executive Report Helpers ===

  def executive_summary
    score = calculate_risk_score
    vulns = vulnerability_summary

    {
      risk_level: risk_level,
      risk_score: score,
      total_vulnerabilities: vulns[:total] || 0,
      critical_issues: vulns[:critical] || 0,
      actionable_items: vulns[:with_fix] || 0,
      scan_date: scan&.scanned_at,
      project_name: project.name
    }
  end

  def key_findings
    findings = []
    return findings unless scan

    vulns = scan.vulnerabilities

    if vulns.critical.any?
      findings << {
        type: "critical",
        message: I18n.t("reports.findings.critical_found", count: vulns.critical.count)
      }
    end

    if vulns.high.any?
      findings << {
        type: "high",
        message: I18n.t("reports.findings.high_found", count: vulns.high.count)
      }
    end

    fix_available = vulns.where.not(fixed_version: [nil, ""])
    if fix_available.any?
      findings << {
        type: "info",
        message: I18n.t("reports.findings.fixes_available", count: fix_available.count)
      }
    end

    findings
  end

  def trend_summary
    scans = project.scans.completed.order(created_at: :desc).limit(5)
    return {} if scans.size < 2

    current = scans.first
    previous = scans.second

    current_total = current.vulnerabilities.count
    previous_total = previous.vulnerabilities.count
    change = current_total - previous_total

    {
      current_total: current_total,
      previous_total: previous_total,
      change: change,
      trend: change.positive? ? "increasing" : (change.negative? ? "decreasing" : "stable")
    }
  end

  def compliance_status
    score = calculate_risk_score
    {
      passing: score < 50,
      score: score,
      threshold: 50,
      message: score < 50 ? I18n.t("reports.compliance.passing") : I18n.t("reports.compliance.failing")
    }
  end

  # === Compliance Report Helpers ===

  def compliance_checks
    checks = []
    return checks unless scan

    vulns = scan.vulnerabilities

    # No critical vulnerabilities
    checks << {
      name: "no_critical_vulnerabilities",
      status: vulns.critical.empty? ? "pass" : "fail",
      message: vulns.critical.empty? ? I18n.t("reports.checks.no_critical_pass") : I18n.t("reports.checks.no_critical_fail", count: vulns.critical.count)
    }

    # All high vulnerabilities have fixes
    high_no_fix = vulns.high.where(fixed_version: [nil, ""])
    checks << {
      name: "high_vulns_have_fixes",
      status: high_no_fix.empty? ? "pass" : "warn",
      message: high_no_fix.empty? ? I18n.t("reports.checks.high_fix_pass") : I18n.t("reports.checks.high_fix_warn", count: high_no_fix.count)
    }

    # Risk score below threshold
    score = calculate_risk_score
    checks << {
      name: "risk_score_threshold",
      status: score < 50 ? "pass" : "fail",
      message: score < 50 ? I18n.t("reports.checks.risk_score_pass") : I18n.t("reports.checks.risk_score_fail", score: score)
    }

    checks
  end

  def policy_violations
    violations = []
    return violations unless scan

    vulns = scan.vulnerabilities

    # Critical vulnerabilities are policy violations
    vulns.critical.each do |v|
      violations << {
        policy: "no_critical_vulnerabilities",
        severity: "critical",
        package: v.affected_package,
        cve_id: v.cve_id
      }
    end

    violations.first(20)
  end

  def license_analysis
    return {} unless scan

    licenses = scan.dependencies.group(:license).count
    {
      total_licenses: licenses.size,
      breakdown: licenses,
      unknown: licenses[nil] || 0
    }
  end

  # === Trend Report Helpers ===

  def vulnerability_trends
    scans = project.scans.completed.order(created_at: :asc).limit(10)
    scans.map do |s|
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

  def dependency_trends
    scans = project.scans.completed.order(created_at: :asc).limit(10)
    scans.map do |s|
      {
        date: s.scanned_at || s.created_at,
        total: s.dependencies.count
      }
    end
  end

  def risk_score_trends
    scans = project.scans.completed.order(created_at: :asc).limit(10)
    scans.map do |s|
      vulns = s.vulnerabilities
      score = (vulns.critical.count * 10) +
              (vulns.high.count * 5) +
              (vulns.medium.count * 2) +
              vulns.low.count
      {
        date: s.scanned_at || s.created_at,
        score: [score, 100].min
      }
    end
  end

  def scan_frequency
    scans = project.scans.completed.order(created_at: :desc).limit(10)
    return {} if scans.size < 2

    intervals = scans.each_cons(2).map { |a, b| (a.created_at - b.created_at) / 1.day }
    avg_days = intervals.sum / intervals.size

    {
      total_scans: project.scans.completed.count,
      average_interval_days: avg_days.round(1),
      last_scan: scans.first.created_at
    }
  end

  def improvement_metrics
    scans = project.scans.completed.order(created_at: :desc).limit(5)
    return {} if scans.size < 2

    first = scans.last
    latest = scans.first

    first_total = first.vulnerabilities.count
    latest_total = latest.vulnerabilities.count

    {
      initial_vulnerabilities: first_total,
      current_vulnerabilities: latest_total,
      reduction: first_total - latest_total,
      reduction_percentage: first_total.positive? ? ((first_total - latest_total).to_f / first_total * 100).round(1) : 0
    }
  end

  # === Common Helpers ===

  def scan_info
    return {} unless scan

    {
      id: scan.id,
      scanned_at: scan.scanned_at,
      sbom_format: scan.sbom_format,
      ecosystem: scan.ecosystem,
      scan_mode: scan.scan_mode,
      duration: scan.duration
    }
  end

  def generate_title
    case report.report_type
    when "summary" then "#{project.name} - Security Summary Report"
    when "detailed" then "#{project.name} - Detailed Security Analysis"
    when "executive" then "#{project.name} - Executive Security Summary"
    when "compliance" then "#{project.name} - Compliance Report"
    when "trend" then "#{project.name} - Security Trend Analysis"
    else "#{project.name} - Security Report"
    end
  end

  def generate_metadata
    {
      generated_by: "SBOM Dashboard",
      version: "1.0",
      scan_id: scan&.id,
      project_id: project.id,
      report_type: report.report_type,
      format: report.format,
      generated_at: Time.current.iso8601
    }
  end

  def generate_file_export
    case report.format
    when "json" then generate_json_export
    when "csv" then generate_csv_export
    when "pdf" then generate_pdf_export
    end
  end

  def generate_json_export
    json_content = {
      metadata: report.metadata,
      content: report.content
    }.to_json

    report.file.attach(
      io: StringIO.new(json_content),
      filename: "#{report.title.parameterize}.json",
      content_type: "application/json"
    )
  end

  def generate_csv_export
    require "csv"

    csv_content = CSV.generate do |csv|
      csv << %w[CVE_ID Severity Package Version Title Fixed_Version CVSS_Score]

      all_vulnerabilities.each do |vuln|
        csv << [
          vuln[:cve_id],
          vuln[:severity],
          vuln[:package_name],
          vuln[:package_version],
          vuln[:title],
          vuln[:fixed_version],
          vuln[:cvss_score]
        ]
      end
    end

    report.file.attach(
      io: StringIO.new(csv_content),
      filename: "#{report.title.parameterize}.csv",
      content_type: "text/csv"
    )
  end

  def generate_pdf_export
    pdf = Prawn::Document.new(page_size: "A4", margin: 40)

    # Header
    pdf_render_header(pdf)

    # Content based on report type
    case report.report_type
    when "summary" then pdf_render_summary(pdf)
    when "detailed" then pdf_render_detailed(pdf)
    when "executive" then pdf_render_executive(pdf)
    when "compliance" then pdf_render_compliance(pdf)
    when "trend" then pdf_render_trend(pdf)
    else pdf_render_summary(pdf)
    end

    # Footer
    pdf_render_footer(pdf)

    report.file.attach(
      io: StringIO.new(pdf.render),
      filename: "#{report.title.parameterize}.pdf",
      content_type: "application/pdf"
    )
  end

  # === PDF Rendering Helpers ===

  def pdf_render_header(pdf)
    pdf.font_size(24) do
      pdf.text report.title, style: :bold, color: "1a1a2e"
    end
    pdf.move_down 5
    pdf.font_size(10) do
      pdf.text "Generated: #{Time.current.strftime('%Y-%m-%d %H:%M')}", color: "666666"
      pdf.text "Project: #{project.name}", color: "666666"
    end
    pdf.stroke_horizontal_rule
    pdf.move_down 20
  end

  def pdf_render_footer(pdf)
    pdf.repeat(:all) do
      pdf.bounding_box([0, 20], width: pdf.bounds.width, height: 20) do
        pdf.font_size(8) do
          pdf.text "Generated by SBOM Dashboard | Page #{pdf.page_number}", align: :center, color: "999999"
        end
      end
    end
  end

  def pdf_render_summary(pdf)
    content = report.content.with_indifferent_access

    # Risk Score Section
    pdf_section_title(pdf, "Risk Overview")
    risk = content[:risk_score] || 0
    pdf.text "Risk Score: #{risk}/100 (#{risk_level.upcase})", size: 14, style: :bold
    pdf.move_down 15

    # Vulnerability Summary
    pdf_section_title(pdf, "Vulnerability Summary")
    vuln_summary = content[:vulnerability_summary] || {}
    pdf_vulnerability_summary_table(pdf, vuln_summary)
    pdf.move_down 15

    # Top Vulnerabilities
    if content[:top_vulnerabilities].present?
      pdf_section_title(pdf, "Top Vulnerabilities")
      pdf_vulnerabilities_table(pdf, content[:top_vulnerabilities])
      pdf.move_down 15
    end

    # Recommendations
    if content[:recommendations].present?
      pdf_section_title(pdf, "Recommendations")
      content[:recommendations].each_with_index do |rec, i|
        pdf.text "#{i + 1}. [#{rec[:priority]&.upcase}] #{rec[:title]}", style: :bold, size: 10
        pdf.text "   #{rec[:description]}", size: 9, color: "444444"
        pdf.move_down 5
      end
    end
  end

  def pdf_render_detailed(pdf)
    content = report.content.with_indifferent_access

    # Summary section
    pdf_render_summary(pdf)

    # All Vulnerabilities
    if content[:all_vulnerabilities].present?
      pdf.start_new_page
      pdf_section_title(pdf, "All Vulnerabilities (#{content[:all_vulnerabilities].size})")
      pdf_vulnerabilities_table(pdf, content[:all_vulnerabilities])
      pdf.move_down 15
    end

    # Remediation Plan
    if content[:remediation_plan].present?
      pdf.start_new_page
      pdf_section_title(pdf, "Remediation Plan")
      content[:remediation_plan].each do |phase|
        pdf.text "Phase #{phase[:phase]}: #{phase[:title]}", style: :bold, size: 11
        phase[:actions]&.each do |action|
          pdf.text "  • #{action[:package]} - #{action[:cve_id]}", size: 9
        end
        pdf.move_down 10
      end
    end

    # Dependencies
    if content[:all_dependencies].present?
      pdf.start_new_page
      pdf_section_title(pdf, "Dependencies (#{content[:all_dependencies].size})")
      pdf_dependencies_table(pdf, content[:all_dependencies].first(50))
    end
  end

  def pdf_render_executive(pdf)
    content = report.content.with_indifferent_access

    # Executive Summary
    exec_summary = content[:executive_summary] || {}
    pdf_section_title(pdf, "Executive Summary")

    pdf.font_size(36) do
      color = case exec_summary[:risk_level]
              when "critical" then "DC2626"
              when "high" then "EA580C"
              when "medium" then "CA8A04"
              else "16A34A"
              end
      pdf.text exec_summary[:risk_score].to_s, style: :bold, color: color, align: :center
    end
    pdf.text "Risk Score", align: :center, size: 10, color: "666666"
    pdf.move_down 20

    # Key Metrics
    pdf.text "Total Vulnerabilities: #{exec_summary[:total_vulnerabilities]}", size: 11
    pdf.text "Critical Issues: #{exec_summary[:critical_issues]}", size: 11
    pdf.text "Actionable Items: #{exec_summary[:actionable_items]}", size: 11
    pdf.move_down 15

    # Key Findings
    if content[:key_findings].present?
      pdf_section_title(pdf, "Key Findings")
      content[:key_findings].each do |finding|
        marker = finding[:type] == "critical" ? "⚠" : "•"
        pdf.text "#{marker} #{finding[:message]}", size: 10
      end
      pdf.move_down 15
    end

    # Compliance Status
    if content[:compliance_status].present?
      pdf_section_title(pdf, "Compliance Status")
      status = content[:compliance_status]
      pdf.text status[:passing] ? "✓ PASSING" : "✗ FAILING",
               style: :bold,
               color: status[:passing] ? "16A34A" : "DC2626",
               size: 14
      pdf.text status[:message], size: 10, color: "666666"
    end
  end

  def pdf_render_compliance(pdf)
    content = report.content.with_indifferent_access

    # Compliance Checks
    if content[:compliance_checks].present?
      pdf_section_title(pdf, "Compliance Checks")
      content[:compliance_checks].each do |check|
        status_color = case check[:status]
                       when "pass" then "16A34A"
                       when "warn" then "CA8A04"
                       else "DC2626"
                       end
        pdf.text "#{check[:status].upcase}: #{check[:message]}", color: status_color, size: 10
        pdf.move_down 5
      end
      pdf.move_down 15
    end

    # Policy Violations
    if content[:policy_violations].present? && content[:policy_violations].any?
      pdf_section_title(pdf, "Policy Violations")
      content[:policy_violations].each do |violation|
        pdf.text "• #{violation[:package]} - #{violation[:cve_id]} (#{violation[:severity]})", size: 9
      end
      pdf.move_down 15
    end

    # License Analysis
    if content[:license_analysis].present?
      pdf_section_title(pdf, "License Analysis")
      analysis = content[:license_analysis]
      pdf.text "Total unique licenses: #{analysis[:total_licenses]}", size: 10
      pdf.text "Unknown licenses: #{analysis[:unknown]}", size: 10
      pdf.move_down 10

      if analysis[:breakdown].present?
        data = [["License", "Count"]]
        analysis[:breakdown].each do |license, count|
          data << [license || "Unknown", count.to_s]
        end
        pdf.table(data, header: true, width: pdf.bounds.width / 2) do |t|
          t.row(0).font_style = :bold
          t.row(0).background_color = "e5e7eb"
          t.cells.padding = 5
          t.cells.size = 9
        end
      end
    end
  end

  def pdf_render_trend(pdf)
    content = report.content.with_indifferent_access

    # Improvement Metrics
    if content[:improvement_metrics].present?
      metrics = content[:improvement_metrics]
      pdf_section_title(pdf, "Improvement Metrics")
      pdf.text "Initial Vulnerabilities: #{metrics[:initial_vulnerabilities]}", size: 10
      pdf.text "Current Vulnerabilities: #{metrics[:current_vulnerabilities]}", size: 10

      change = metrics[:reduction] || 0
      color = change.positive? ? "16A34A" : (change.negative? ? "DC2626" : "666666")
      pdf.text "Change: #{change >= 0 ? '-' : '+'}#{change.abs} (#{metrics[:reduction_percentage]}%)",
               size: 12, style: :bold, color: color
      pdf.move_down 15
    end

    # Scan Frequency
    if content[:scan_frequency].present?
      freq = content[:scan_frequency]
      pdf_section_title(pdf, "Scan Frequency")
      pdf.text "Total Scans: #{freq[:total_scans]}", size: 10
      pdf.text "Average Interval: #{freq[:average_interval_days]} days", size: 10
      pdf.move_down 15
    end

    # Vulnerability Trends Table
    if content[:vulnerability_trends].present?
      pdf_section_title(pdf, "Vulnerability Trends")
      data = [["Date", "Total", "Critical", "High", "Medium", "Low"]]
      content[:vulnerability_trends].each do |trend|
        date = trend[:date].is_a?(String) ? trend[:date] : trend[:date]&.strftime("%Y-%m-%d")
        data << [date, trend[:total], trend[:critical], trend[:high], trend[:medium], trend[:low]]
      end
      pdf.table(data, header: true, width: pdf.bounds.width) do |t|
        t.row(0).font_style = :bold
        t.row(0).background_color = "e5e7eb"
        t.cells.padding = 5
        t.cells.size = 9
        t.columns(1..5).align = :center
      end
    end
  end

  def pdf_section_title(pdf, title)
    pdf.font_size(14) do
      pdf.text title, style: :bold, color: "1a1a2e"
    end
    pdf.move_down 10
  end

  def pdf_vulnerability_summary_table(pdf, summary)
    data = [
      ["Severity", "Count"],
      ["Critical", summary[:critical] || 0],
      ["High", summary[:high] || 0],
      ["Medium", summary[:medium] || 0],
      ["Low", summary[:low] || 0],
      ["Total", summary[:total] || 0]
    ]

    pdf.table(data, header: true, width: 200) do |t|
      t.row(0).font_style = :bold
      t.row(0).background_color = "e5e7eb"
      t.row(1).background_color = "fef2f2" if (summary[:critical] || 0) > 0
      t.row(2).background_color = "fff7ed" if (summary[:high] || 0) > 0
      t.cells.padding = 5
      t.cells.size = 10
      t.columns(1).align = :center
    end
  end

  def pdf_vulnerabilities_table(pdf, vulnerabilities)
    return if vulnerabilities.blank?

    data = [["CVE ID", "Severity", "Package", "CVSS", "Fix"]]
    vulnerabilities.first(30).each do |v|
      data << [
        v[:cve_id].to_s.truncate(20),
        v[:severity].to_s,
        v[:package].presence || "#{v[:package_name]}@#{v[:package_version]}".truncate(25),
        v[:cvss_score].to_s,
        v[:has_fix] ? "Yes" : "No"
      ]
    end

    pdf.table(data, header: true, width: pdf.bounds.width) do |t|
      t.row(0).font_style = :bold
      t.row(0).background_color = "e5e7eb"
      t.cells.padding = 4
      t.cells.size = 8
      t.columns(1).width = 60
      t.columns(3..4).align = :center
    end
  end

  def pdf_dependencies_table(pdf, dependencies)
    return if dependencies.blank?

    data = [["Name", "Version", "Ecosystem", "License"]]
    dependencies.each do |d|
      data << [
        d[:name].to_s.truncate(30),
        d[:version].to_s,
        d[:ecosystem].to_s,
        (d[:license] || "-").to_s.truncate(15)
      ]
    end

    pdf.table(data, header: true, width: pdf.bounds.width) do |t|
      t.row(0).font_style = :bold
      t.row(0).background_color = "e5e7eb"
      t.cells.padding = 4
      t.cells.size = 8
    end
  end
end
