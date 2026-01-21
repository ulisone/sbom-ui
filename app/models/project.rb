class Project < ApplicationRecord
  belongs_to :user
  belongs_to :organization, optional: true
  has_many :scans, dependent: :destroy
  has_many :vulnerabilities, through: :scans
  has_many :dependencies, through: :scans
  has_many :reports, dependent: :destroy
  has_many :vulnerability_histories, dependent: :destroy
  has_many :policies, dependent: :destroy
  has_many :policy_violations, through: :policies

  validates :name, presence: true

  # Returns projects accessible to a user (owned or through organization membership)
  scope :accessible_by, ->(user) {
    left_joins(:organization)
      .left_joins(organization: :memberships)
      .where("projects.user_id = ? OR memberships.user_id = ?", user.id, user.id)
      .distinct
  }

  def accessible_by?(user)
    return true if user_id == user.id
    return false unless organization.present?
    organization.member?(user)
  end

  def editable_by?(user)
    return true if user_id == user.id
    return false unless organization.present?
    organization.can_edit?(user)
  end

  def manageable_by?(user)
    return true if user_id == user.id
    return false unless organization.present?
    organization.can_manage?(user)
  end

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
