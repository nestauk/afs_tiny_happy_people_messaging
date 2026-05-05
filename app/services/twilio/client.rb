require "twilio-ruby"

module Twilio
  class Client
    def initialize
      @client = Twilio::REST::Client.new(ENV.fetch("TWILIO_ACCOUNT_SID"), ENV.fetch("TWILIO_AUTH_TOKEN"))
    end

    def send_message(message)
      return unless ENV.fetch("SMS_ENABLED", "false") == "true"

      sms = @client
        .messages
        .create(
          body: message.body,
          messaging_service_sid: ENV.fetch("TWILIO_MESSAGING_SERVICE_SID"),
          to: message.user.phone_number,
          status_callback: "#{ENV.fetch("CALLBACK_URL")}/messages/status",
        )

      message.update(status: sms.status, message_sid: sms.sid)
    rescue Twilio::REST::RestError
      Appsignal.report_error(StandardError.new("Twilio message failed")) do
        Appsignal.add_tags(message_id: message.id, user_id: message.user.id)
      end

      message.update(status: "failed")
    end
  end
end
