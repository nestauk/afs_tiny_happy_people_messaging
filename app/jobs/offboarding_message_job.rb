class OffboardingMessageJob < ApplicationJob
  queue_as :background
  include Rails.application.routes.url_helpers

  def perform(user)
    survey = Survey.find_by(title_en: "Offboarding")
    return if survey.blank? || SurveySend.exists?(user: user, survey: survey)
    survey_url = edit_survey_url(survey, token: user.generate_token_for(:survey_token))

    message = Message.build do |m|
      m.user = user
      m.body = I18n.t(".messages.offboarding", locale: user.language || I18n.default_locale).gsub("{{link}}", survey_url)
    end

    if message.save
      SendCustomMessageJob.perform_later(message)
    end
  end
end
