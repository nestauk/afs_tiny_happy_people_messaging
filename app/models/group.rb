class Group < ApplicationRecord
  has_many :contents, dependent: :destroy

  validates :name, :age_in_months, presence: true
end
