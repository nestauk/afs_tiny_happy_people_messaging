require "test_helper"

class UpdateMessageStatusJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#perform should update message status" do
    message = create(:message, message_sid: "123")

    UpdateMessageStatusJob.new.perform({MessageSid: message.message_sid, MessageStatus: "delivered"})

    message.reload
    assert_equal "delivered", message.status
    assert_not_nil message.sent_at
  end

  test "#perform should not override delivered status" do
    message = create(:message, status: "delivered", message_sid: "123")

    UpdateMessageStatusJob.new.perform({MessageSid: message.message_sid, MessageStatus: "delivered"})

    message.reload
    assert_equal "delivered", message.status
  end

  test "#perform should not crash if it can't find the message" do
    assert_nothing_raised do
      UpdateMessageStatusJob.new.perform({MessageSid: "123", MessageStatus: "delivered"})
    end
  end
end
