require "aws-sdk-pinpointsmsvoicev2"

module Sms
  class AwsAdapter
    AWS_FAILED_EVENT_TYPES = %w[
      TEXT_INVALID
      TEXT_UNREACHABLE
      TEXT_BLOCKED
      TEXT_CARRIER_BLOCKED
      TEXT_CARRIER_UNREACHABLE
      TEXT_INVALID_MESSAGE
      TEXT_SPAM
      TEXT_TTL_EXPIRED
      TEXT_UNKNOWN
    ].freeze

    def initialize(message)
      @message = message
      @client = Aws::PinpointSMSVoiceV2::Client.new(
        region: ENV.fetch("AWS_REGION"),
        access_key_id: ENV.fetch("AWS_SMS_ACCESS_KEY_ID"),
        secret_access_key: ENV.fetch("AWS_SMS_SECRET_ACCESS_KEY"),
      )
    end

    def deliver
      sms = @client.send_text_message(
        destination_phone_number: @message.user.phone_number,
        origination_identity: ENV.fetch("AWS_SMS_ORIGINATION_ID"),
        message_body: @message.body,
        message_type: "TRANSACTIONAL",
        configuration_set_name: ENV.fetch("AWS_SMS_CONFIG_SET_NAME"),
      )

      @message.update(status: "sent", message_sid: sms.message_id)
    rescue Aws::PinpointSMSVoiceV2::Errors::ServiceError => e
      Appsignal.report_error(e) do
        Appsignal.add_tags(message_id: @message.id, user_id: @message.user.id)
      end

      @message.update(status: "failed")
    end
  end
end
