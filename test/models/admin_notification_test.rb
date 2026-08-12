require "test_helper"

class AdminNotificationTest < ActiveSupport::TestCase
  test ".already_sent_today? is false when no notification exists" do
    assert_not AdminNotification.already_sent_today?
  end

  test ".already_sent_today? is true when a notification exists for today" do
    create(:admin_notification)

    assert AdminNotification.already_sent_today?
  end

  test ".already_sent_today? is false when a notification exists for a previous day" do
    create(:admin_notification, sent_on: 1.day.ago.to_date)

    assert_not AdminNotification.already_sent_today?
  end

  test "sent_on is unique, preventing two notifications on the same day" do
    create(:admin_notification)

    assert_raises(ActiveRecord::RecordNotUnique) do
      create(:admin_notification)
    end
  end
end
