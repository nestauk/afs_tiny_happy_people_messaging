class SendWaitlistMessageJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :background

  def perform(user)
    message = Message.build do |m|
      m.token = m.send(:generate_token)
      m.user = user
      m.body = substitute_variables(Content::WAITLIST_MESSAGE, user)
    end

    Twilio::Client.new.send_message(message) if message.save
  end

  private

  def substitute_variables(content, user)
    translations = {
      "{{parent_name}}": user.first_name
    }

    content.gsub(/{{parent_name}}/) do |match|
      translations[match.to_sym]
    end
  end
end
