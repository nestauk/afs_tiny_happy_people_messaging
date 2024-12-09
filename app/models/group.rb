class Group < ApplicationRecord
  has_many :contents, dependent: :destroy

  validates :name, presence: true
end
