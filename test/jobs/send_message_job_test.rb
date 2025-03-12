require "test_helper"

class SendMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  test "#perform sends messages with default content" do
    content = create(:content, body: "Hi {{parent_name}}, here is a link for {{child_name}}: {{link}}")
    content2 = create(:content, group: content.group, body: "Hi {{parent_name}}, here is a link for {{child_name}}: {{link}}")
    user = create(:user, last_content_id: content.id, first_name: "John", child_name: "Billy")

    Message.any_instance.stubs(:generate_token).returns("123")

    stub_successful_twilio_call("Hi John, here is a link for Billy: {{link}}".gsub("{{link}}", track_link_url("123")), user)

    SendMessageJob.new.perform(user)

    assert_equal 1, Message.count
    assert_equal content2, Message.last.content
    assert_match(/m\/123/, Message.last.body)
    assert_match(/John/, Message.last.body)
    assert_match(/Billy/, Message.last.body)
    assert_equal content2.id, user.reload.last_content_id
  end

  test "#perform sends message if child name is missing" do
    content = create(:content, body: "Hi {{parent_name}}, here is a link for {{child_name}}: {{link}}")
    user = create(:user, first_name: "John")

    Message.any_instance.stubs(:generate_token).returns("123")

    stub_successful_twilio_call("Hi John, here is a link for your child: {{link}}".gsub("{{link}}", track_link_url("123")), user)

    SendMessageJob.new.perform(user)

    assert_equal 1, Message.count
    assert_equal content, Message.last.content
    assert_match(/m\/123/, Message.last.body)
    assert_match(/John/, Message.last.body)
    assert_match(/your child/, Message.last.body)
    assert_equal content.id, user.reload.last_content_id
  end

  test "#perform does not send message if no appropriate content available" do
    assert_no_changes -> { Message.count } do
      SendMessageJob.new.perform(create(:user))
    end
  end

  test "#perform does not send message if user already has the same message" do
    user = create(:user)
    group = create(:group)
    content = create(:content, group:)

    create(:message, user:, content:)

    assert_no_changes -> { Message.count } do
      SendMessageJob.new.perform(user)
    end
  end

  test "#perform does not send message if user has had a message this week" do
    user = create(:user)
    group = create(:group)
    content = create(:content, group:)

    create(:message, user: user, content: content, created_at: 1.day.ago)

    assert_no_changes -> { Message.count } do
      SendMessageJob.new.perform(user)
    end
  end

  test "#perform does not send message if user fails to update" do
    content = create(:content, body: "here is a link: {{link}}")
    create(:content, group: content.group, body: "here is a link: {{link}}")
    user = build(:user, last_content_id: content.id, child_birthday: 3.years.ago)
    user.save(validate: false)

    Message.any_instance.stubs(:generate_token).returns("123")

    assert_no_changes -> { Message.count } do
      SendMessageJob.new.perform(user)
    end

    assert_equal content.id, user.reload.last_content_id
  end
end
