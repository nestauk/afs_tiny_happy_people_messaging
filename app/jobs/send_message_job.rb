class SendMessageJob < ApplicationJob
  queue_as :default

  def perform(user, group)
    return unless group.present?

    content = user.next_content(group)&.body

    return unless content.present?

    message = Message.create(
      user:,
      body: user.next_content(group).body,
      content: user.next_content(group)
    )

    Twilio::Client.new.send_message(message)
  end
end
