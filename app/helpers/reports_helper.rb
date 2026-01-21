module ReportsHelper
  def risk_score_bg_class(score)
    score = score.to_i
    case score
    when 0..20
      "bg-low-bg"
    when 21..50
      "bg-medium-bg"
    when 51..80
      "bg-high-bg"
    else
      "bg-critical-bg"
    end
  end

  def risk_score_text_class(score)
    score = score.to_i
    case score
    when 0..20
      "text-low"
    when 21..50
      "text-medium"
    when 51..80
      "text-high"
    else
      "text-critical"
    end
  end

  def risk_level(score)
    score = score.to_i
    case score
    when 0..20
      "low"
    when 21..50
      "medium"
    when 51..80
      "high"
    else
      "critical"
    end
  end

  def risk_level_bg_class(level)
    case level.to_s.downcase
    when "low"
      "bg-low-bg"
    when "medium"
      "bg-medium-bg"
    when "high"
      "bg-high-bg"
    when "critical"
      "bg-critical-bg"
    else
      "bg-surface-hover"
    end
  end

  def risk_level_icon(level)
    case level.to_s.downcase
    when "low"
      '<svg class="w-6 h-6 text-low" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" /></svg>'.html_safe
    when "medium"
      '<svg class="w-6 h-6 text-medium" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" /></svg>'.html_safe
    when "high"
      '<svg class="w-6 h-6 text-high" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" /></svg>'.html_safe
    when "critical"
      '<svg class="w-6 h-6 text-critical" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" /></svg>'.html_safe
    else
      '<svg class="w-6 h-6 text-text-muted" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-8-3a1 1 0 00-.867.5 1 1 0 11-1.731-1A3 3 0 0113 8a3.001 3.001 0 01-2 2.83V11a1 1 0 11-2 0v-1a1 1 0 011-1 1 1 0 100-2zm0 8a1 1 0 100-2 1 1 0 000 2z" clip-rule="evenodd" /></svg>'.html_safe
    end
  end

  def severity_badge_class(severity)
    case severity.to_s.upcase
    when "CRITICAL"
      "badge-critical"
    when "HIGH"
      "badge-high"
    when "MEDIUM"
      "badge-medium"
    when "LOW"
      "badge-low"
    else
      "badge bg-surface-hover text-text-secondary"
    end
  end

  def recommendation_priority_class(priority)
    case priority.to_s.downcase
    when "critical"
      "bg-critical text-white"
    when "high"
      "bg-high text-white"
    when "medium"
      "bg-medium text-white"
    when "low"
      "bg-low text-white"
    else
      "bg-primary text-white"
    end
  end

  def compliance_check_icon(status)
    case status.to_s.downcase
    when "pass"
      '<svg class="w-5 h-5 text-low" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" /></svg>'.html_safe
    when "fail"
      '<svg class="w-5 h-5 text-critical" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" /></svg>'.html_safe
    when "warn"
      '<svg class="w-5 h-5 text-medium" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" /></svg>'.html_safe
    else
      '<svg class="w-5 h-5 text-text-muted" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" /></svg>'.html_safe
    end
  end

  def compliance_check_class(status)
    case status.to_s.downcase
    when "pass"
      "bg-low-bg border-low"
    when "fail"
      "bg-critical-bg border-critical"
    when "warn"
      "bg-medium-bg border-medium"
    else
      "bg-surface-hover border-border"
    end
  end
end
