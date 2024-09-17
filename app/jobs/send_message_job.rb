require "twilio-ruby"

class SendMessageJob < ApplicationJob
  queue_as :default

  def perform(user:, body: "")
    content = user.next_content&.body || body
    return unless content.present?

    @client = Twilio::REST::Client.new(ENV.fetch("TWILIO_ACCOUNT_SID"), ENV.fetch("TWILIO_AUTH_TOKEN"))

    message = @client
      .messages
      .create(
        body: content,
        from: ENV.fetch("TWILIO_PHONE_NUMBER"),
        to: user.phone_number,
        status_callback: "#{ENV.fetch("CALLBACK_URL")}/messages/status"
      )

    Message.create(
      user:,
      body: message.body,
      message_sid: message.sid,
      status: message.status,
      content: user.next_content || nil
    )
  end
end
