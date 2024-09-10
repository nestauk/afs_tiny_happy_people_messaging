require "twilio-ruby"

class SendMessageJob < ApplicationJob
  queue_as :default

  def perform(user)
    account_sid = ENV.fetch('TWILIO_ACCOUNT_SID')
    auth_token = ENV.fetch('TWILIO_AUTH_TOKEN')
    @client = Twilio::REST::Client.new(account_sid, auth_token)

    @client
      .messages
      .create(
        body: 'Hi again',
        from: '+447830364524',
        to: '+447549533404'
      )

    Message.create(user: user, body: 'Your appointment is coming up on July 21 at 3PM')
  end
end
