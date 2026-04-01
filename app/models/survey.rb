class Survey < ApplicationRecord
  has_many :questions, dependent: :destroy
  has_many :survey_sends, dependent: :destroy
  has_many :users, through: :survey_sends
  accepts_nested_attributes_for :questions

  validates :title_en, :title_cy, presence: true

  def self.trigger_for(user, message_count:, last_message: false)
    already_sent_ids = user.survey_sends.select(:survey_id)

    surveys = where.not(id: already_sent_ids)

    matching = surveys.select do |survey|
      (survey.send_after_message_count == message_count) ||
        (last_message && survey.send_on_last_message?)
    end

    matching.each { |survey| SendSurveyJob.perform_later(user, survey) }
  end
end
