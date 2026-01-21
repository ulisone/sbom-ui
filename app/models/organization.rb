class Organization < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :projects, dependent: :nullify
  has_many :policies, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9\-]+\z/, message: "only allows lowercase letters, numbers, and hyphens" }

  before_validation :generate_slug, on: :create

  scope :ordered, -> { order(:name) }

  # Role constants
  ROLES = %w[owner admin member viewer].freeze
  OWNER = "owner".freeze
  ADMIN = "admin".freeze
  MEMBER = "member".freeze
  VIEWER = "viewer".freeze

  def owner
    memberships.find_by(role: OWNER)&.user
  end

  def owners
    users.joins(:memberships).where(memberships: { role: OWNER })
  end

  def admins
    users.joins(:memberships).where(memberships: { role: [OWNER, ADMIN] })
  end

  def members_with_role(role)
    users.joins(:memberships).where(memberships: { role: role })
  end

  def add_member(user, role: MEMBER, invited_by: nil)
    memberships.create(user: user, role: role, invited_by: invited_by, accepted_at: Time.current)
  end

  def remove_member(user)
    memberships.find_by(user: user)&.destroy
  end

  def member?(user)
    memberships.exists?(user: user)
  end

  def role_for(user)
    memberships.find_by(user: user)&.role
  end

  def can_manage?(user)
    role = role_for(user)
    role.in?([OWNER, ADMIN])
  end

  def can_edit?(user)
    role = role_for(user)
    role.in?([OWNER, ADMIN, MEMBER])
  end

  def can_view?(user)
    member?(user)
  end

  private

  def generate_slug
    return if slug.present?
    return unless name.present?

    base_slug = name.parameterize
    self.slug = base_slug

    counter = 1
    while Organization.exists?(slug: slug)
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end
end
