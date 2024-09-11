class User < ApplicationRecord
  has_many :interests
  has_many :messages, dependent: :destroy
  validates :phone_number, :first_name, :last_name, :child_age, presence: true
  validates_uniqueness_of :phone_number
  phony_normalize :phone_number, default_country_code: "UK"

  accepts_nested_attributes_for :interests

  scope :contactable, -> { where(contactable: true) }

  def calculated_child_age
    child_age + ((Time.now.to_date.year * 12 + Time.now.to_date.month) - (created_at.to_date.year * 12 + created_at.to_date.month))
  end

  def full_name
    "#{first_name} #{last_name}"
  end
end
