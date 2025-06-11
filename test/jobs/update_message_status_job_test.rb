require "test_helper"

class UpdateMessageStatusJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#perform should update message status" do
    message = create(:message, message_sid: "123")

    UpdateMessageStatusJob.new.perform({MessageSid: message.message_sid, MessageStatus: "failed"})

    message.reload
    assert_equal "failed", message.status
  end

  test "#perform should not crash if it can't find the message" do
    assert_nothing_raised do
      UpdateMessageStatusJob.new.perform({MessageSid: "123", MessageStatus: "delivered"})
    end
  end
end
