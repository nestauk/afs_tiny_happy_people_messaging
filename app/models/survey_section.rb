class SurveySection < ApplicationRecord
  has_many :questions, dependent: :destroy
  belongs_to :survey

  validates :title_en, :title_cy, :position, presence: true
end
