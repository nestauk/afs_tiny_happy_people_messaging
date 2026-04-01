class Question < ApplicationRecord
  belongs_to :survey
  positioned on: :survey
  has_many :answers, dependent: :destroy
  accepts_nested_attributes_for :answers

  validates :text_en, :text_cy, :question_type, :position, presence: true
  validate :options_presence_for_choice_types

  private

  def options_presence_for_choice_types
    if %w[check_boxes radio_buttons].include?(question_type) && (options_en.blank? || options_cy.blank?)
      errors.add(:base, "Both English and Welsh options must be present for this question type.")
    end
  end
end
