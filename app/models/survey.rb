class Survey < ApplicationRecord
  has_many :survey_sections, dependent: :destroy
  has_many :questions, through: :survey_sections
  has_many :survey_sends, dependent: :destroy
  has_many :users, through: :survey_sends
  accepts_nested_attributes_for :questions

  validates :title_en, :title_cy, presence: true

  has_rich_text :intro_en
  has_rich_text :intro_cy

  def self.trigger_for(user, message_count:)
    already_sent_ids = user.survey_sends.select(:survey_id)

    surveys = where.not(id: already_sent_ids)

    matching = surveys.select do |survey|
      survey.send_after_message_count == message_count
    end

    matching.each { |survey| SendSurveyJob.perform_later(user, survey) }
  end
end
