class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :organization
  belongs_to :invited_by, class_name: "User", optional: true

  validates :role, presence: true, inclusion: { in: Organization::ROLES }
  validates :user_id, uniqueness: { scope: :organization_id, message: "is already a member of this organization" }

  scope :accepted, -> { where.not(accepted_at: nil) }
  scope :pending, -> { where(accepted_at: nil) }
  scope :owners, -> { where(role: Organization::OWNER) }
  scope :admins, -> { where(role: [Organization::OWNER, Organization::ADMIN]) }

  def accepted?
    accepted_at.present?
  end

  def pending?
    accepted_at.nil?
  end

  def accept!
    update!(accepted_at: Time.current)
  end

  def owner?
    role == Organization::OWNER
  end

  def admin?
    role.in?([Organization::OWNER, Organization::ADMIN])
  end

  def can_manage?
    admin?
  end

  def can_edit?
    role.in?([Organization::OWNER, Organization::ADMIN, Organization::MEMBER])
  end

  def role_display
    I18n.t("organizations.roles.#{role}", default: role.titleize)
  end
end
