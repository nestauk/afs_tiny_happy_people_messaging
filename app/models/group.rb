class Group < ApplicationRecord
  has_many :contents, dependent: :destroy
  has_many :users, dependent: :nullify

  validates :name, :language, presence: true
end
