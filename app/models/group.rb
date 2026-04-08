class Group < ApplicationRecord
  has_many :contents, dependent: :destroy
  has_many :users, dependent: :restrict_with_error

  validates :name, :language, presence: true
end
