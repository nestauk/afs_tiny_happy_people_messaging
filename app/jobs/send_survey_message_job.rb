class SendSurveyMessageJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :default

  def perform(user)
    content = "Hi {{parent_name}}, got 10 minutes? We’d love to hear your thoughts on the programme so far! It will help us make the service better for your family and give you a chance to win a £20 One4All gift voucher. Simply take this quick survey: https://survey.alchemer.com/s3/8240837/Tiny-Happy-People-Text-Messaging-Programme-Feedback-Survey"

    message = Message.build do |m|
      m.user = user
      m.body = substitute_variables(content, m)
    end

    Twilio::Client.new.send_message(message) if save_user_and_message(user, message, content)
  end

  private

  def save_user_and_message(user, message, content)
    ActiveRecord::Base.transaction do
      user.update!(sent_survey_at: Time.now)
      message.save!
    rescue ActiveRecord::RecordInvalid => e
      Rollbar.error(e, user_info: user.attributes, message_info: message.attributes)
      false
    end
  end

  def substitute_variables(content, message)
    translations = {
      "{{parent_name}}": message.user.first_name
    }

    content.gsub(/{{parent_name}}/) do |match|
      translations[match.to_sym]
    end
  end
end
