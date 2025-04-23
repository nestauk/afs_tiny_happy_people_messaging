class Content < ApplicationRecord
  belongs_to :group
  positioned on: :group

  has_many :messages, dependent: :restrict_with_exception

  validates_presence_of :body, :link, :age_in_months

  scope :active, -> { where(archived_at: nil) }

  def archived?
    archived_at.present?
  end
end
