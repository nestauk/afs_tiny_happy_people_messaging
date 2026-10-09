class Survey < ApplicationRecord
  has_many :survey_sections, dependent: :destroy
  has_many :questions, through: :survey_sections
  has_many :answers, through: :questions
  has_many :survey_sends, dependent: :destroy
  has_many :users, through: :survey_sends
  accepts_nested_attributes_for :questions

  validates :title_en, :title_cy, presence: true

  has_rich_text :intro_en
  has_rich_text :intro_cy

  def completed_by?(user)
    survey_sends.where(user: user).where.not(completed_at: nil).exists?
  end

  def completed_respondent_count
    survey_sends.where.not(completed_at: nil).distinct.count(:user_id)
  end

  def full?
    max_responses.present? && completed_respondent_count >= max_responses
  end
end
