class User < ApplicationRecord
  has_many :interests
  has_many :messages, dependent: :destroy
  validates :phone_number, :first_name, :last_name, :child_age, presence: true
  phony_normalize :phone_number, default_country_code: 'UK'

  accepts_nested_attributes_for :interests

  scope :contactable, -> { where(contactable: true) }
end
