class User < ApplicationRecord
  devise :registerable

  validates :phone_number, :first_name, :last_name, presence: true
end
