class RestartMessagesJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :default

  def perform(user)
    if user.update(contactable: true)
      message = Message.create(user: user, body: "Welcome back to Tiny Happy People! Text 'END' to unsubscribe at any time.")

      Twilio::Client.new.send_message(message)
    end
  end
end
