class SendBroadcastJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :default

  def perform(broadcast)
    broadcast.matching_users.find_in_batches do |users|
      jobs = users.filter_map do |user|
        message = create_message_and_survey(broadcast, user)

        SendCustomMessageJob.new(message) if message
      end

      ActiveJob.perform_all_later(jobs) if jobs.any?
    end

    broadcast.update!(sent_at: Time.zone.now)
  end

  private

  def create_message_and_survey(broadcast, user)
    Message.transaction do
      message = Message.create!(
        user: user,
        broadcast: broadcast,
        body: substitute_variables(broadcast, user),
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
  rescue ActiveRecord::RecordInvalid => e
    Appsignal.report_error("Message and/or SurveySend failed to persist: #{e.message}")
  end

  def substitute_variables(broadcast, user)
    translations = {
      "{{first_name}}": user.first_name || "",
      "{{survey_link}}": broadcast.survey.present? ? edit_survey_url(broadcast.survey, token: user.generate_token_for(:survey_token)) : "",
    }

    body = (user.language == "en") ? broadcast.body_en : broadcast.body_cy

    result = body.gsub(/({{first_name}}|{{survey_link}})/) do |match|
      translations[match.to_sym]
    end

    result.gsub(/\s+([!?,.:])/, '\1').gsub(/\s{2,}/, " ").strip
  end
end
