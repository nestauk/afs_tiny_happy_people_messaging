class Interest < ApplicationRecord
  belongs_to :user, optional: true

  validates :title, presence: true

  attr_accessor :other_title

  TITLES = [
    "Building a better routine with my child",
    "Sharing special moments together",
    "Finding fresh ideas for activities with my child",
    "Feeling supported through parenting ups and downs",
    "Building on my existing parenting skills",
  ]
end
