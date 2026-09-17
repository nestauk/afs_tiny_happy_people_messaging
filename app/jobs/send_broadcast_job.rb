class SendBroadcastJob < ApplicationJob
  include Rails.application.routes.url_helpers
  include MessageVariableSubstitution

  queue_as :background

  def perform(broadcast)
    sent_any = false
    already_messaged_user_ids = broadcast.messages.select(:user_id)

    broadcast.matching_users.where.not(id: already_messaged_user_ids).find_in_batches do |users|
      jobs = users.filter_map do |user|
        message = create_message_and_survey(broadcast, user)
        sent_any ||= message.present?

        SendCustomMessageJob.new(message) if message
      end

      ActiveJob.perform_all_later(jobs) if jobs.any?
    end

    broadcast.update!(sent_at: Time.zone.now) if sent_any
  end

  private

  def create_message_and_survey(broadcast, user)
    Message.transaction do
      message = Message.create!(
        user: user,
        broadcast: broadcast,
        body: substitute_variables(body_for(broadcast, user), user, survey_link: survey_link_for(broadcast, user)),
      )

      if broadcast.survey.present?
        SurveySend.create!(
          user: user,
          survey: broadcast.survey,
          sent_at: Time.zone.now,
        )
      end

      message
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid => e
    Appsignal.report_error("Message and/or SurveySend failed to persist: #{e.message}")
  end

  def body_for(broadcast, user)
    (user.language == "en") ? broadcast.body_en : broadcast.body_cy
  end

  def survey_link_for(broadcast, user)
    return if broadcast.survey.blank?

    edit_survey_url(broadcast.survey, token: user.generate_token_for(:survey_token))
  end
end
