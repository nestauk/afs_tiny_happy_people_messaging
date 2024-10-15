class Page < ApplicationRecord
  has_many :clicks

  validates :name, presence: true
end
