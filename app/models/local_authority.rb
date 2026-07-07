class LocalAuthority < ApplicationRecord
  has_many :users
  has_many :messages, through: :users
  validates :name, presence: true
end
