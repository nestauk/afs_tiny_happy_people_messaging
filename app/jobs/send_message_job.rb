require "twilio-ruby"

class SendMessageJob < ApplicationJob
  queue_as :default

  def perform(user)
    account_sid = ENV.fetch('TWILIO_ACCOUNT_SID')
    auth_token = ENV.fetch('TWILIO_AUTH_TOKEN')
    @client = Twilio::REST::Client.new(account_sid, auth_token)

    message = @client
      .messages
      .create(
        body: 'Hi again',
        from: '+447830364524',
        to: user.phone_number,
        status_callback: 'https://c815-167-98-16-36.ngrok-free.app/messages/status'
      )

    Message.create(user:, body: message.body, message_sid: message.sid, status: message.status)
  end
end
