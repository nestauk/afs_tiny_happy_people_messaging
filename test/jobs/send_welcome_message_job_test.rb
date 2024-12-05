require "test_helper"

class SendWelcomeMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  test "#perform sends message with default content" do
    user = create(:user, child_birthday: 18.months.ago)
    group = create(:group)
    content = create(:content, group:, welcome_message: true, link: "https://example.com", body: "Hi, {{link}}")
    create(:content, group:, welcome_message: false, link: "https://example.com")

    Message.any_instance.stubs(:generate_token).returns("123")

    stub_successful_twilio_call(content.body.gsub("{{link}}", track_link_url("123")), user)

    SendWelcomeMessageJob.new.perform(user)

    assert_equal 1, Message.count
    assert_match(/m\/123/, Message.last.body)
    assert_equal "https://example.com", Message.last.link
    assert_equal user.reload.last_content_id, content.id
  end

  test "#perform sends message with no link if there isn't appropriate content" do
    user = create(:user, child_birthday: 25.months.ago)

    Message.any_instance.stubs(:generate_token).returns("123")

    message = "Welcome to Tiny Happy People, a programme of weekly texts with fun activities! You'll receive your first activity soon."

    stub_successful_twilio_call(message, user)

    SendWelcomeMessageJob.new.perform(user)

    assert_equal 1, Message.count
    assert_nil Message.last.link
    assert_nil user.reload.last_content_id
  end

  test "#perform sends message with no link if there isn't a welcome message" do
    user = create(:user, child_birthday: 18.months.ago)
    group = create(:group)
    create(:content, group:, welcome_message: false, link: "https://example.com")

    Message.any_instance.stubs(:generate_token).returns("123")

    message = "Welcome to Tiny Happy People, a programme of weekly texts with fun activities! You'll receive your first activity soon."

    stub_successful_twilio_call(message, user)

    SendWelcomeMessageJob.new.perform(user)

    assert_equal 1, Message.count
    assert_nil Message.last.link
    assert_nil user.reload.last_content_id
  end
end
