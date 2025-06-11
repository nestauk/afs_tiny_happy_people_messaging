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

  test "#generate_reply only runs if message status is received" do
    user = create(:user)
    message = create(:message, status: "delivered", user:, body: "stop")

    assert message.user.contactable
  end

  test "#generate_reply when user texts stop" do
    create(:auto_response, trigger_phrase: "stop", update_user: "{\"contactable\": false}")
    message = create(:message, body: "stop", status: "received")

    refute message.user.contactable
  end

  test "#generate_reply when user texts start" do
    create(:auto_response, trigger_phrase: "start", update_user: "{\"contactable\": true}")
    message = create(:message, body: "start", status: "received")

    assert message.user.contactable
  end

  test "#generate_reply when user texts anything else" do
    message = build(:message, body: "blah", status: "received")

    ResponseMatcherService.expects(:new).with(message).returns(stub(match_response: true))
    message.save
  end

  test "#admin_status returns the status of the message" do
    message = create(:message, status: "delivered")
    assert_equal "Delivered", message.admin_status

    message.update(clicked_at: Time.current)
    assert_equal "Clicked", message.admin_status

    message.update(status: "failed", clicked_at: nil)
    assert_equal "Failed", message.admin_status
  end

  test "#set_token sets the token" do
    message = build(:message)
    assert_nil message.token

    message.save
    assert_not_nil message.token
  end
end
