class Report < ApplicationRecord
  belongs_to :project
  belongs_to :scan, optional: true

  has_one_attached :file

  validates :report_type, presence: true, inclusion: { in: %w[summary detailed executive compliance trend] }
  validates :status, presence: true, inclusion: { in: %w[pending generating completed failed] }
  validates :format, presence: true, inclusion: { in: %w[html pdf csv json] }

  enum :status, {
    pending: "pending",
    generating: "generating",
    completed: "completed",
    failed: "failed"
  }, default: :pending

  REPORT_TYPES = %w[summary detailed executive compliance trend].freeze
  FORMATS = %w[html pdf csv json].freeze

  scope :recent, -> { order(created_at: :desc) }
  scope :completed, -> { where(status: :completed) }

  def report_type_display
    I18n.t("reports.types.#{report_type}", default: report_type.titleize)
  end

  def format_display
    format.upcase
  end

  def vulnerability_summary
    content["vulnerability_summary"] || {}
  end

  def dependency_summary
    content["dependency_summary"] || {}
  end

  def risk_score
    content["risk_score"] || 0
  end

  def recommendations
    content["recommendations"] || []
  end

  def trends
    content["trends"] || {}
  end
end
