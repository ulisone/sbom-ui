class Project < ApplicationRecord
  belongs_to :user
  has_many :scans, dependent: :destroy
  has_many :vulnerabilities, through: :scans
  has_many :dependencies, through: :scans

  validates :name, presence: true

  def latest_scan
    scans.order(created_at: :desc).first
  end

  def total_vulnerabilities
    vulnerabilities.count
  end

  def critical_vulnerabilities
    vulnerabilities.where(severity: "CRITICAL").count
  end

  def high_vulnerabilities
    vulnerabilities.where(severity: "HIGH").count
  end

  def vulnerability_summary
    {
      critical: vulnerabilities.where(severity: "CRITICAL").count,
      high: vulnerabilities.where(severity: "HIGH").count,
      medium: vulnerabilities.where(severity: "MEDIUM").count,
      low: vulnerabilities.where(severity: "LOW").count
    }
  end
end
