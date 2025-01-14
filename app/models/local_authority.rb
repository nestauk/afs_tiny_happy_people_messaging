class LocalAuthority < ApplicationRecord
  has_many :users
  validates :name, presence: true

  scope :most_users_order, -> { left_joins(:users).group(:id).order("COUNT(users.id) DESC") }
end
