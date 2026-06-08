require "twilio-ruby"

module Sms
  class TwilioAdapter
    def initialize(message)
      @client = Twilio::REST::Client.new(ENV.fetch("TWILIO_ACCOUNT_SID", nil), ENV.fetch("TWILIO_AUTH_TOKEN", nil))
      @message = message
    end

    def deliver
      sms = @client
        .messages
        .create(
          body: @message.body,
          messaging_service_sid: ENV.fetch("TWILIO_MESSAGING_SERVICE_SID"),
          to: @message.user.phone_number,
          status_callback: "#{ENV.fetch("CALLBACK_URL")}/messages/twilio_status",
        )

      @message.update(status: sms.status, message_sid: sms.sid)
    rescue Twilio::REST::RestError => e
      Appsignal.report_error(e) do
        Appsignal.add_tags(message_id: @message.id, user_id: @message.user.id)
      end

      @message.update(status: "failed")
    end
  end
end
