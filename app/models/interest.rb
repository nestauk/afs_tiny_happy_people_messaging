class Interest < ApplicationRecord
  belongs_to :user, optional: true

  validates :title, presence: true

  attr_accessor :other_title

  TITLES = [
    "Bond with my child",
    "Improve my parenting confidence",
    "Feel supported on my parenting journey",
    "Get language development tips"
  ]
end
