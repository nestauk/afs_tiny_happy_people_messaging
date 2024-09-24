class SendMessageJob < ApplicationJob
  queue_as :default

  def perform(user, group)
    return unless group.present?

    content = user.next_content(group)

    return unless content.present?

    message = Message.create(
      user:,
      body: content.body,
      content:
    )

    Twilio::Client.new.send_message(message)
  end
end
