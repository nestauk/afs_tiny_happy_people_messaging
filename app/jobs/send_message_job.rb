class SendMessageJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :default

  def perform(user, group)
    return unless group.present?

    content = user.next_content(group)

    return unless content.present?

    message = Message.create(
      user:,
      body: content.body.gsub("{{link}}", messages_next_url(token: user.token)),
      content:
    )

    Twilio::Client.new.send_message(message)
  end
end
