ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"
require "webmock/minitest"

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods

    WebMock.disable_net_connect!(
      allow_localhost: true,
      allow: /vite-test/,
    )

    def assert_present(key, msg: "can't be blank", subject: @subject, value: nil)
      subject.send(:"#{key}=", value)
      subject.valid?
      assert_error(key, msg)
    end

    def assert_field_has_errors(label_text)
      find_field(label_text).assert_ancestor(".input_wrapper.field_with_errors")
    end

    def assert_field_has_errors_not_simple_form(label_text, error_message)
      field = find_field(label_text)
      error_id = field["aria-describedby"]
      assert error_id, "Expected field '#{label_text}' to have aria-describedby"
      error_element = find_by_id(error_id)
      assert_match(error_message, error_element.text)
    end

    def assert_error(key, msg, subject: @subject)
      assert_includes(subject.errors[key], msg)
    end

    def stub_successful_twilio_call(message, user)
      stub_request(:post, "https://api.twilio.com/2010-04-01/Accounts/#{ENV.fetch("TWILIO_ACCOUNT_SID")}/Messages.json")
        .with(
          body: {"Body" => message, "MessagingServiceSid" => ENV.fetch("TWILIO_MESSAGING_SERVICE_SID"), "StatusCallback" => "/messages/twilio_status", "To" => user.phone_number},
        )
        .to_return(status: 200, body: {"body" => message, "status" => "accepted", "sid" => "123"}.to_json)
    end

    def stub_unsuccessful_twilio_call(message, user)
      stub_request(:post, "https://api.twilio.com/2010-04-01/Accounts/#{ENV.fetch("TWILIO_ACCOUNT_SID")}/Messages.json")
        .with(
          body: {"Body" => message, "MessagingServiceSid" => ENV.fetch("TWILIO_MESSAGING_SERVICE_SID"), "StatusCallback" => "/messages/twilio_status", "To" => user.phone_number},
        )
        .to_return(status: 500, body: {"body" => message, "status" => "failed", "sid" => "123"}.to_json)
    end

    def stub_successful_aws_call(message, user, aws_message_id: "aws-message-id")
      stub_request(:post, %r{https://sms-voice\..+\.amazonaws\.com/})
        .with do |request|
          body = ::JSON.parse(request.body)
          body["DestinationPhoneNumber"] == user.phone_number &&
            body["OriginationIdentity"] == ENV.fetch("AWS_SMS_ORIGINATION_ID") &&
            body["MessageBody"] == message &&
            body["MessageType"] == "TRANSACTIONAL"
        end
        .to_return(
          status: 200,
          body: {"MessageId" => aws_message_id}.to_json,
          headers: {"Content-Type" => "application/x-amz-json-1.0"},
        )
    end

    def stub_unsuccessful_aws_call(message, user)
      stub_request(:post, %r{https://sms-voice\..+\.amazonaws\.com/})
        .with do |request|
          body = ::JSON.parse(request.body)
          body["DestinationPhoneNumber"] == user.phone_number &&
            body["MessageBody"] == message
        end
        .to_return(
          status: 400,
          body: {"__type" => "ValidationException", "Message" => "Invalid phone number"}.to_json,
          headers: {"Content-Type" => "application/x-amz-json-1.0"},
        )
    end

    def stub_sns_verification_success
      Aws::SNS::MessageVerifier.any_instance.stubs(:authenticate!).returns(true)
    end

    def sns_notification_envelope(**event_attrs)
      {
        "Type" => "Notification",
        "TopicArn" => "arn:aws:sns:eu-west-2:123:topic",
        "Message" => event_attrs.transform_keys(&:to_s).to_json,
      }
    end

    def assert_see(text)
      document = ActionView::Base.full_sanitizer.sanitize(@response.body.gsub(/^.*<body>(.*)<\/body>.*$/mi, "\\1")).gsub(/\s{2,}/, "\n").strip
      match = document.match(text)
      assert document.match(text), "Expected to see \"#{text}\" in:\n#{document}"

      match
    end

    def assert_dont_see(text)
      document = ActionView::Base.full_sanitizer.sanitize(@response.body.gsub(/^.*<body>(.*)<\/body>.*$/mi, "\\1")).gsub(/\s{2,}/, "\n").strip
      assert !document.match(text), "Expected not to see \"#{text}\" in:\n#{document}"
    end

    setup do
      stub_location_geocoder
    end

    def stub_location_geocoder
      geocode_payload = Geokit::GeoLoc.new(country_code: "Wales")
      LocationGeocoder.any_instance.stubs(:geocode).returns(geocode_payload)
    end

    def teardown
      super

      Rails.cache.clear
      ActionMailer::Base.deliveries.clear
    end
  end
end
