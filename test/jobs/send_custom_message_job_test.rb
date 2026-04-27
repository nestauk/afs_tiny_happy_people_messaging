require "test_helper"

class SendCustomMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#perform sends messages" do
    message = create(:message)

    stub_successful_twilio_call(message.body, message.user)

    ENV["SMS_ENABLED"] = "true"
    SendCustomMessageJob.perform_now(message)
    ENV["SMS_ENABLED"] = "false"

    reloaded_message = message.reload

    assert_equal "accepted", reloaded_message.status
  end
end
