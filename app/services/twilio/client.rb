require "twilio-ruby"

module Twilio
  class Client
    def initialize
      @client = Twilio::REST::Client.new(ENV.fetch("TWILIO_ACCOUNT_SID"), ENV.fetch("TWILIO_AUTH_TOKEN"))
    end

    def send_message(message)
      sms = @client
        .messages
        .create(
          body: message.body,
          messaging_service_sid: ENV.fetch("TWILIO_MESSAGING_SERVICE_SID"),
          to: message.user.phone_number,
          status_callback: "#{ENV.fetch("CALLBACK_URL")}/messages/status"
        )

      message.update(status: sms.status, message_sid: sms.sid)
    rescue Twilio::REST::RestError
      message.update(status: "failed")
    end
  end
end
