class Interest < ApplicationRecord
  belongs_to :user, optional: true

  validates :title, presence: true

  attr_accessor :other_title
end
