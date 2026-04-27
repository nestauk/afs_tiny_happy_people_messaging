require "test_helper"

class SendCustomMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#perform sends messages" do
    message = create(:message)

    stub_successful_twilio_call(message.body, message.user)

    SendCustomMessageJob.perform_now(message)

    reloaded_message = message.reload

    assert_equal "accepted", reloaded_message.status
  end
end
