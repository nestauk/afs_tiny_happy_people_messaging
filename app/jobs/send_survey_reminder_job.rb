class SendSurveyReminderJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :background

  def perform(user, survey)
    survey_url = edit_survey_url(survey, token: user.generate_token_for(:survey_token))

    message = Message.build do |m|
      m.token = m.send(:generate_token)
      m.user = user
      m.body = I18n.t(".messages.survey_reminder", locale: user.language || I18n.default_locale).gsub("{{survey_url}}", survey_url)
    end

    if message.save
      SendCustomMessageJob.perform_later(message)
      SurveySend.create!(user: user, survey: survey, sent_at: Time.zone.now)
    end
  end
end
