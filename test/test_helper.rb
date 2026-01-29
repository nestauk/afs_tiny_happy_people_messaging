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
      allow: ["vite-test:3037", "chromedriver.storage.googleapis.com"]
    )

    def assert_present(key, msg: "can't be blank", subject: @subject, value: nil)
      subject.send(:"#{key}=", value)
      subject.valid?
      assert_error(key, msg)
    end

    def assert_field_has_errors(label_text)
      find_field(label_text).assert_ancestor(".input_wrapper.field_with_errors")
    end

    def assert_error(key, msg, subject: @subject)
      assert_includes(subject.errors[key], msg)
    end

    def stub_successful_twilio_call(message, user)
      stub_request(:post, "https://api.twilio.com/2010-04-01/Accounts/#{ENV.fetch("TWILIO_ACCOUNT_SID")}/Messages.json")
        .with(
          body: {"Body" => message, "MessagingServiceSid" => ENV.fetch("TWILIO_MESSAGING_SERVICE_SID"), "StatusCallback" => "/messages/status", "To" => user.phone_number}
        )
        .to_return(status: 200, body: {"body" => message, "status" => "accepted", "sid" => "123"}.to_json)
    end

    def stub_unsuccessful_twilio_call(message, user)
      stub_request(:post, "https://api.twilio.com/2010-04-01/Accounts/#{ENV.fetch("TWILIO_ACCOUNT_SID")}/Messages.json")
        .with(
          body: {"Body" => message, "MessagingServiceSid" => ENV.fetch("TWILIO_MESSAGING_SERVICE_SID"), "StatusCallback" => "/messages/status", "To" => user.phone_number}
        )
        .to_return(status: 500, body: {"body" => message, "status" => "failed", "sid" => "123"}.to_json)
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

    def teardown
      super

      Rails.cache.clear
      ActionMailer::Base.deliveries.clear
    end
  end
end
