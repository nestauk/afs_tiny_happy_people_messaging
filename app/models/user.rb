class User < ApplicationRecord
  has_many :interests
  validates :phone_number, :first_name, :last_name, :child_age, presence: true
end
