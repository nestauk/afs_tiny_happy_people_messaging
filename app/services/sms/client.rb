module Sms
  class Client
    # Our AWS Pinpoint account's default send rate is 20 SMS/second; batch bulk
    # sends comfortably under that so we don't trigger Aws::PinpointSMSVoiceV2::Errors::ThrottlingException.
    BATCH_SIZE = 15

    def initialize(message)
      @message = message
    end

    def send_message
      return unless ENV.fetch("SMS_ENABLED", "false") == "true"

      adapter = adapter_class
      return if adapter.nil?

      adapter.new(@message).deliver
    end

    private

    def adapter_class
      case @message.user.sms_provider
      when "twilio" then Sms::TwilioAdapter
      when "aws" then Sms::AwsAdapter
      else
        Appsignal.report_error(StandardError.new("Unsupported SMS provider: #{@message.user.sms_provider.inspect}"))
      end
    end
  end
end
