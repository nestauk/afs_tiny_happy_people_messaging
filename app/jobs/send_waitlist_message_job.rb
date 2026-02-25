class SendWaitlistMessageJob < ApplicationJob
  include Rails.application.routes.url_helpers
  include MessageVariableSubstitution

  queue_as :background

  def perform(user)
    message = Message.build do |m|
      m.user = user
      m.body = substitute_variables(Content::WAITLIST_MESSAGE, user)
    end

    Twilio::Client.new.send_message(message) if message.save
  end
end
