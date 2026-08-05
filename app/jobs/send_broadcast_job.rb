class SendBroadcastJob < ApplicationJob
  queue_as :default

  def perform(broadcast)
    broadcast.matching_users.find_each do |user|
      ## Survey send object
      message = Message.create!(
        user: user,
        broadcast: broadcast,
        body: user.language == "cy" ? broadcast.substitute_variables(broadcast.body_cy, user) : broadcast.substitute_variables(broadcast.body_en, user),
      )
      SendCustomMessageJob.perform_later(message)
    end
    broadcast.update!(sent_at: Time.zone.now)
  end

  private

  def substitute_variables(body, user)
    translations = {
      "{{first_name}}": user.first_name || "",
      "{{survey_link}}": survey.present? ? edit_survey_url(survey, token: user.generate_token_for(:survey_token)) : "",
    }

    result = body.gsub(/({{first_name}}|{{survey_link}})/) do |match|
      translations[match.to_sym]
    end

    result.gsub(/\s+([!?,.:])/, '\1').gsub(/\s{2,}/, " ").strip
  end
end
