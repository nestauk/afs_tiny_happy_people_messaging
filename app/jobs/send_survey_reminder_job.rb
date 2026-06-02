class SendSurveyReminderJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :background

  def perform(user, survey)
    return if SurveySend.where(user: user, survey: survey, sent_at: Time.zone.now.beginning_of_day..).exists?
    return if SurveySend.where(user: user, survey: survey).count >= 2

    survey_url = edit_survey_url(survey, token: user.generate_token_for(:survey_token))

    message = Message.build do |m|
      m.user = user
      m.body = I18n.t(".messages.survey_reminder", locale: user.language || I18n.default_locale).gsub("{{survey_url}}", survey_url)
    end

    if message.save
      SendCustomMessageJob.perform_later(message)
      SurveySend.create!(user: user, survey: survey, sent_at: Time.zone.now)
    else
      Appsignal.report_error(StandardError.new("Failed to send survey reminder message")) do
        Appsignal.add_tags(user_id: user.id, errors: message.errors.full_messages)
      end
    end
  end
end
