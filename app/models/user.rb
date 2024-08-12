class User < ApplicationRecord
  has_many :interests
  has_many :messages, dependent: :destroy
  validates :phone_number, :first_name, :last_name, :child_age, presence: true

  accepts_nested_attributes_for :interests
end
