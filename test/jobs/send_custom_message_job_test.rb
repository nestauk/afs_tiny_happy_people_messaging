require "test_helper"

class SendCustomMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#perform sends messages" do
    user = create(:user)

    stub_successful_twilio_call("Custom Body", user)

    SendCustomMessageJob.perform_now(user, "Custom Body")

    assert_equal 1, Message.count
    assert_equal "Custom Body", Message.last.body
  end

  test "#perform doesn't send message with no content" do
    user = create(:user)

    SendCustomMessageJob.perform_now(user, "")

    assert_equal 0, Message.count
  end
end
