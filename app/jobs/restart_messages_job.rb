class RestartMessagesJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :default

  def perform(user)
    if user.update(contactable: true)
      message = Message.create(user: user, body: I18n.t(".messages.restart"))

      Twilio::Client.new.send_message(message)
    end
  end
end
