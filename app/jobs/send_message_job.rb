require "twilio-ruby"

class SendMesssageJob < ApplicationJob
  queue_as :default

  def perform(user)
    account_sid = 'ACce1a82c5472be1601a839d874f9ce235'
    auth_token = 'c1db592b532111a36f590e6f95cca58b'
    @client = Twilio::REST::Client.new(account_sid, auth_token)

    @client.messages.create(
      body: 'Your appointment is coming up on July 21 at 3PM',
      from: 'whatsapp:+14155238886',
      to: 'whatsapp:+447549533404'
    )

    Message.create(user: user, body: 'Your appointment is coming up on July 21 at 3PM')
  end
end
