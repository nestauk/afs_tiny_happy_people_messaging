ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"
require "webmock/minitest"

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods

    WebMock.disable_net_connect!(allow_localhost: true)

    def assert_present(key, msg: "can't be blank", subject: @subject, value: nil)
      subject.send(:"#{key}=", value)
      subject.valid?
      assert_error(key, msg)
    end

    def assert_error(key, msg, subject: @subject)
      assert_includes(subject.errors[key], msg)
    end

    def stub_successful_twilio_call(message, user)
      stub_request(:post, "https://api.twilio.com/2010-04-01/Accounts/#{ENV.fetch("TWILIO_ACCOUNT_SID")}/Messages.json")
        .with(
          body: {"Body" => message, "From" => ENV.fetch("TWILIO_PHONE_NUMBER"), "StatusCallback" => "/messages/status", "To" => user.phone_number}
        )
        .to_return(status: 200, body: {"body" => message, "status" => "delivered"}.to_json)
    end

    def stub_unsuccessful_twilio_call(message, user)
      stub_request(:post, "https://api.twilio.com/2010-04-01/Accounts/#{ENV.fetch("TWILIO_ACCOUNT_SID")}/Messages.json")
        .with(
          body: {"Body" => message, "From" => ENV.fetch("TWILIO_PHONE_NUMBER"), "StatusCallback" => "/messages/status", "To" => user.phone_number}
        )
        .to_return(status: 500, body: {}.to_json)
    end
  end
end
