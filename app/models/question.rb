class Question < ApplicationRecord
  belongs_to :survey
  positioned on: :survey
  has_many :answers, dependent: :destroy
  accepts_nested_attributes_for :answers

  validates :text, :question_type, :position, presence: true
end
