require "twilio-ruby"

class SendMessageJob < ApplicationJob
  queue_as :default

  def perform(user:, body: '')
    account_sid = ENV.fetch('TWILIO_ACCOUNT_SID')
    auth_token = ENV.fetch('TWILIO_AUTH_TOKEN')
    @client = Twilio::REST::Client.new(account_sid, auth_token)

    message_body = if body.blank?
      Content.find_by(lower_age: user.calculated_child_age).body
    else
      body
    end

    message = @client
      .messages
      .create(
        body: message_body,
        from: '+447830364524',
        to: user.phone_number,
        status_callback: 'https://c815-167-98-16-36.ngrok-free.app/messages/status'
      )

    Message.create(user:, body: message.body, message_sid: message.sid, status: message.status, content: Content.find_by(lower_age: user.child_age))
  end
end
