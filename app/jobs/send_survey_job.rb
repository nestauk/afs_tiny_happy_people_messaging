class SendSurveyJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :background

  def perform(user, survey)
    return if SurveySend.exists?(user: user, survey: survey)

    survey_url = edit_survey_url(survey, token: user.generate_token_for(:survey_token))

    message = Message.build do |m|
      m.token = m.send(:generate_token)
      m.user = user
      m.body = "We'd love to hear how you're getting on! Please take a moment to complete this short survey: #{survey_url}"
    end

    if message.save
      SendCustomMessageJob.perform_later(message)
      SurveySend.create!(user: user, survey: survey, sent_at: Time.zone.now)
    end
  end
end
