class Interest < ApplicationRecord
  belongs_to :user, optional: true

  validates :title, presence: true

  attr_accessor :other_title

  TITLES = [
    "I want to share special moments with my child",
    "I'm looking to build my confidence as a parent",
    "I need to feel more supported through parenting ups and downs",
    "I want to discover helpful parenting tips and advice"
  ]
end
