module Sms
  class Client
    def initialize(message)
      @message = message
    end

    def send_message
      return unless ENV.fetch("SMS_ENABLED", "false") == "true"

      adapter_class.new(@message).deliver
    end

    private

    def adapter_class
      case @message.user.sms_provider
      when "twilio" then Sms::TwilioAdapter
      when "aws" then Sms::AwsAdapter
      else
        raise StandardError.new("Unsupported SMS provider: #{@message.user.sms_provider.inspect}")
      end
    rescue => e
      Appsignal.report_error(e)
    end
  end
end
