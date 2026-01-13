class Scan < ApplicationRecord
  belongs_to :project
  has_many :dependencies, dependent: :destroy
  has_many :vulnerabilities, dependent: :destroy

  # File attachments for dependency files
  has_many_attached :dependency_files

  validates :status, presence: true
  validates :sbom_format, inclusion: { in: %w[cyclonedx spdx], allow_nil: true }
  validates :scan_mode, inclusion: { in: %w[local sbom_engine], allow_nil: true }

  enum :status, {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }, default: :pending

  scope :recent, -> { order(created_at: :desc) }
  scope :completed, -> { where(status: :completed) }

  ECOSYSTEMS = %w[npm pypi rubygems maven go nuget cargo].freeze
  SCAN_MODES = %w[local sbom_engine].freeze

  def vulnerability_summary
    {
      critical: vulnerabilities.where(severity: "CRITICAL").count,
      high: vulnerabilities.where(severity: "HIGH").count,
      medium: vulnerabilities.where(severity: "MEDIUM").count,
      low: vulnerabilities.where(severity: "LOW").count
    }
  end

  def total_vulnerabilities
    vulnerabilities.count
  end

  def sbom_format_display
    case sbom_format
    when "cyclonedx" then "CycloneDX"
    when "spdx" then "SPDX"
    else sbom_format&.upcase
    end
  end

  def duration
    return nil unless scanned_at && created_at
    scanned_at - created_at
  end

  def use_sbom_engine?
    scan_mode == "sbom_engine"
  end

  def scan_mode_display
    case scan_mode
    when "sbom_engine" then "SBOM Engine"
    when "local" then "Local (Trivy)"
    else "Local"
    end
  end
end
