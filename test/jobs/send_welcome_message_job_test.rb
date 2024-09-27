require "test_helper"

class SendWelcomeMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  test "#perform sends message with default content" do
    user = create(:user, child_birthday: 18.months.ago)

    Message.any_instance.stubs(:generate_token).returns("123")

    message = "Hi #{user.first_name}, welcome to Tiny Happy People. Here's a video to get you started: #{track_link_url(123)}"

    stub_successful_twilio_call(message, user)

    SendWelcomeMessageJob.new.perform(user)

    assert_equal 1, Message.count
    assert_match(/m\/123/, Message.last.body)
    assert_equal "https://www.youtube.com/watch?v=3p6h9f1qk8k", Message.last.link
  end
end
