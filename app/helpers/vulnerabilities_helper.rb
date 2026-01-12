module VulnerabilitiesHelper
  # 심각도를 한글로 변환
  def severity_korean(severity)
    return I18n.t('vulnerabilities.severity.unknown') if severity.blank?
    I18n.t("vulnerabilities.severity.#{severity.downcase}", default: severity)
  end

  def cvss_color_class(score)
    return "border-text-muted text-text-muted" if score.nil?

    score = score.to_f
    if score >= 9.0
      "border-critical text-critical"
    elsif score >= 7.0
      "border-high text-high"
    elsif score >= 4.0
      "border-medium text-medium"
    else
      "border-low text-low"
    end
  end

  def detect_ecosystem(package_name)
    return :unknown if package_name.blank?

    # Try to detect ecosystem from package name patterns
    case package_name
    when /^@[\w-]+\/[\w-]+$/ # npm scoped packages
      :npm
    when /^[a-z]+\.[a-z]+\.[a-z]+/i # Maven-style packages (com.example.package)
      :maven
    when /^github\.com\/|^golang\.org\/|^gopkg\.in\// # Go packages
      :go
    else
      # Check common package patterns
      python_packages = %w[django flask requests numpy pandas scipy tensorflow pytorch pillow celery boto3 sqlalchemy]
      ruby_packages = %w[rails devise sidekiq puma rspec factory_bot rubocop bundler rake]
      rust_packages = %w[tokio serde actix hyper rocket diesel clap reqwest]

      if python_packages.any? { |p| package_name.downcase.start_with?(p) }
        :pip
      elsif ruby_packages.any? { |p| package_name.downcase.start_with?(p) }
        :gem
      elsif rust_packages.any? { |p| package_name.downcase.start_with?(p) }
        :cargo
      else
        :npm # Default to npm for generic package names
      end
    end
  end
end
