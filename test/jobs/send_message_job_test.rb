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
    assert_no_changes -> { Message.count } do
      SendMessageJob.new.perform(create(:user), create(:group))
    end
  end

  test "#perform does not send message if user already has the same message" do
    user = create(:user)
    group = create(:group, age_in_months: user.child_age_in_months_today)
    content = create(:content, group: group)

    create(:message, user: user, content: content)

    assert_no_changes -> { Message.count } do
      SendMessageJob.new.perform(user, group)
    end
  end

  test "#perform does not send message if user has had a message this week" do
    user = create(:user)
    group = create(:group, age_in_months: user.child_age_in_months_today)
    content = create(:content, group: group)

    create(:message, user: user, content: content, created_at: 1.day.ago)

    assert_no_changes -> { Message.count } do
      SendMessageJob.new.perform(user, group)
    end
  end
end
