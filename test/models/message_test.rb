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

  test "generate_reply when user texts 2 weeks" do
    message = create(:message, body: "2weeks", status: "received")
    assert_equal message.user.restart_at, 2.weeks.from_now.noon
  end

  test "generate_reply when user texts 1 month" do
    message = create(:message, body: "1 month   ", status: "received")
    assert_equal message.user.restart_at, 1.month.from_now.noon
  end

  test "generate_reply when user texts 3 months" do
    message = create(:message, body: "3 months", status: "received")
    assert_equal message.user.restart_at, 3.months.from_now.noon
  end

  test "generate_reply when user texts adjust" do
    user = create(:user)
    message = create(:message, user:, body: " adjust please", status: "received")
    assert_equal message.user.adjust_amount, -1

    message = create(:message, user:, body: "ADJUST AGAIN", status: "received")

    assert_equal message.user.adjust_amount, -2
  end
end
