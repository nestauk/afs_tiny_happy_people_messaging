class User < ApplicationRecord
  validates :phone_number, :first_name, :last_name, presence: true
end
