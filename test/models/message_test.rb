require "test_helper"

class MessageTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @message = build(:message)
  end

  test "should be valid" do
    assert @message.valid?
  end

  test "body should be present" do
    @message.body = ""
    assert_not @message.valid?
  end

  test "body can be blank if user is anonymised" do
    user = create(:user, anonymised_at: Time.current)
    message = build(:message, user:, body: "")
    assert message.valid?
  end

  test "#generate_reply only runs if message status is received" do
    user = create(:user)
    assert_enqueued_jobs 0 do
      create(:message, status: "delivered", user:, body: "stop")
    end
  end

  test "#generate_reply when user texts stop" do
    create(:auto_response, trigger_phrase: "stop", update_user: "{\"contactable\": false}")
    assert_enqueued_jobs 1, only: ResponseMatcherJob do
      create(:message, body: "stop", status: "received")
    end
  end

  test "#generate_reply when user texts start" do
    create(:auto_response, trigger_phrase: "start", update_user: "{\"contactable\": true}")
    assert_enqueued_jobs 1, only: ResponseMatcherJob do
      create(:message, body: "start", status: "received")
    end
  end

  test "#generate_reply when user texts anything else" do
    message = build(:message, body: "blah", status: "received")
    assert_enqueued_jobs 1, only: ResponseMatcherJob do
      message.save
    end
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
