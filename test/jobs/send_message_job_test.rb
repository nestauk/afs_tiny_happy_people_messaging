require "test_helper"

class SendMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  test "#perform sends messages with default content" do
    user = create(:user)
    group = create(:group, age_in_months: user.child_age_in_months_today)
    content = create(:content, group:, body: "here is a link: {{link}}")

    Message.any_instance.stubs(:generate_token).returns("123")

    stub_successful_twilio_call(content.body.gsub("{{link}}", track_link_url("123")), user)

    SendMessageJob.new.perform(user, group)

    assert_equal 1, Message.count
    assert_equal content, Message.last.content
    assert_match(/m\/123/, Message.last.body)
  end

  test "#perform does not send message if no appropriate content available" do
    SendMessageJob.new.perform(create(:user), create(:group))
    assert_equal 0, Message.count
  end
end
