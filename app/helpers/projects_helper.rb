module ProjectsHelper
  def event_dot_class(event)
    case event.event_type
    when VulnerabilityHistory::DISCOVERED
      "bg-critical"
    when VulnerabilityHistory::FIXED
      "bg-low"
    when VulnerabilityHistory::UPGRADED
      "bg-high"
    when VulnerabilityHistory::DOWNGRADED
      "bg-medium"
    when VulnerabilityHistory::REAPPEARED
      "bg-critical"
    else
      "bg-text-muted"
    end
  end

  def render_event_icon(event)
    icon = case event.event_type
           when VulnerabilityHistory::DISCOVERED
             '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />'
           when VulnerabilityHistory::FIXED
             '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />'
           when VulnerabilityHistory::UPGRADED
             '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />'
           when VulnerabilityHistory::DOWNGRADED
             '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 17h8m0 0V9m0 8l-8-8-4 4-6-6" />'
           when VulnerabilityHistory::REAPPEARED
             '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />'
           else
             '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />'
           end

    content_tag(:svg, icon.html_safe,
      class: "w-4 h-4 #{event.event_icon_class}",
      fill: "none",
      stroke: "currentColor",
      viewBox: "0 0 24 24"
    )
  end
end
