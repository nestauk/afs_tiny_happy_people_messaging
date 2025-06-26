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

    def create_all_auto_responses
      create(:auto_response, trigger_phrase: "yes", response: "That's great to hear, thanks for letting us know!", update_user: "{\"asked_for_feedback\": false}", user_conditions: "{\"asked_for_feedback\": true}", update_content_adjustment: '{"needs_adjustment": false}', content_adjustment_conditions: "{\"needs_adjustment\": null}")
      create(:auto_response, trigger_phrase: "no", response: "We can adjust the activities we send to be more relevant based on your child's needs. Respond 1 if too easy, 2 if too hard, or reply with your message if you want to give more context.", update_user: "{\"asked_for_feedback\": false}", user_conditions: "{\"asked_for_feedback\": true}", update_content_adjustment: "{\"needs_adjustment\": true}", content_adjustment_conditions: "{\"needs_adjustment\": null}")

      create(:auto_response, trigger_phrase: "1", response: "Thanks for the feedback. Are you one of these groups? {{content_age_groups}}", user_conditions: "{\"contactable\": true}", update_content_adjustment: "{\"direction\": \"up\", \"number_options\": \"number_options\"}", content_adjustment_conditions: "{\"needs_adjustment\": true, \"direction\": null}")
      create(:auto_response, trigger_phrase: "2", response: "Thanks for the feedback. Are you one of these groups? {{content_age_groups}}", user_conditions: "{\"contactable\": true}", update_content_adjustment: "{\"direction\": \"down\", \"number_options\": \"number_options\"}", content_adjustment_conditions: "{\"needs_adjustment\": true, \"direction\": null}")

      create(:auto_response, trigger_phrase: "1", response: "Thanks, we've adjusted the content you'll receive. We'll check back in in a few weeks to make sure it's right.", user_conditions: "{\"contactable\": true}", update_content_adjustment: "{\"needs_adjustment\": false, \"adjusted_at\": \"now\"}", content_adjustment_conditions: "{\"needs_adjustment\": true, \"direction\": \"not_nil\"}")
      create(:auto_response, trigger_phrase: "2", response: "Thanks, we've adjusted the content you'll receive. We'll check back in in a few weeks to make sure it's right.", user_conditions: "{\"contactable\": true}", update_content_adjustment: "{\"needs_adjustment\": false, \"adjusted_at\": \"now\"}", content_adjustment_conditions: "{\"needs_adjustment\": true, \"direction\": \"not_nil\"}")

      create(:auto_response, trigger_phrase: "2", response: "Thanks, a member of the team will be in touch to discuss your child's needs.", user_conditions: '{ "contactable": true}', content_adjustment_conditions: '{"needs_adjustment": true, "direction": "not_nil", "number_options": 1}', update_content_adjustment: '{"direction": "not_sure"}')
      create(:auto_response, trigger_phrase: "3", response: "Thanks, a member of the team will be in touch to discuss your child's needs.", user_conditions: '{ "contactable": true}', content_adjustment_conditions: '{"needs_adjustment": true, "direction": "not_nil", "number_options": 2}', update_content_adjustment: '{"direction": "not_sure"}')
    end
  end
end
