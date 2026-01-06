class Group < ApplicationRecord
  has_many :contents, dependent: :destroy

  validates :name, :language, presence: true
end
