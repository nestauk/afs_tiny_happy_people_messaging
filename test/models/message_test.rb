require "test_helper"

class MessageTest < ActiveSupport::TestCase
  def setup
    @message = build(:message)
  end

  test "should be valid" do
    assert @message.valid?
  end

  test "content should be present" do
    @message.body = ""
    assert_not @message.valid?
  end

  test "generate_reply only runs if message status is received" do
    user = create(:user)
    message = create(:message, status: "delivered", user:, body: "stop")
    assert_equal message.user.contactable, true
  end

  test "generate_reply when user texts stop" do
    message = create(:message, body: "stop", status: "received")
    assert_equal message.user.contactable, false
  end

  test "generate_reply when user texts start" do
    message = create(:message, body: "start", status: "received")
    assert_equal message.user.contactable, true
  end

  test "generate_reply when user texts pause" do
    message = create(:message, body: "pause", status: "received")
    assert_equal message.user.contactable, false
    assert_not_nil message.user.restart_at
  end
end
