class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :projects, dependent: :destroy
  has_many :scans, through: :projects
  has_many :vulnerabilities, through: :scans
  has_many :reports, through: :projects

  # Organization memberships
  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships
  has_many :owned_organizations, -> { joins(:memberships).where(memberships: { role: Organization::OWNER }) },
           through: :memberships, source: :organization

  # Notifications
  has_many :notifications, dependent: :destroy
  has_one :notification_preference, dependent: :destroy

  # Activity logs
  has_many :activity_logs, dependent: :nullify

  after_create :create_notification_preference!

  def display_name
    name.presence || email.split("@").first
  end

  def member_of?(organization)
    memberships.exists?(organization: organization)
  end

  def role_in(organization)
    memberships.find_by(organization: organization)&.role
  end

  def can_manage?(organization)
    organization.can_manage?(self)
  end

  def can_edit_in?(organization)
    organization.can_edit?(self)
  end

  def can_view?(organization)
    organization.can_view?(self)
  end

  def accessible_projects
    Project.accessible_by(self)
  end

  def unread_notifications_count
    notifications.unread.count
  end

  def notification_preferences
    notification_preference || create_notification_preference!
  end
end
