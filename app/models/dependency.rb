class Dependency < ApplicationRecord
  belongs_to :scan

  validates :name, presence: true

  scope :by_ecosystem, ->(ecosystem) { where(ecosystem: ecosystem) }

  def full_name
    version.present? ? "#{name}@#{version}" : name
  end

  def purl_type
    return nil unless purl.present?
    purl.match(/pkg:(\w+)\//)&.[](1)
  end
end
