require "test_helper"

class RetryFailedMessagesJobTest < ActiveSupport::TestCase
  test "#perform retries messages that failed within the last hour" do
    message = create(:message, status: "failed", created_at: 30.minutes.ago)
    client = mock
    client.expects(:send_message)

    Sms::Client.expects(:new).with(message).returns(client)

    RetryFailedMessagesJob.new.perform
  end

  test "#perform does not retry messages that failed more than an hour ago" do
    create(:message, status: "failed", created_at: 2.hours.ago)

    Sms::Client.expects(:new).never

    RetryFailedMessagesJob.new.perform
  end

  test "#perform does not retry messages that are not failed" do
    create(:message, status: "delivered", created_at: 30.minutes.ago)

    Sms::Client.expects(:new).never

    RetryFailedMessagesJob.new.perform
  end

  test "#perform does not retry failed messages belonging to anonymised users" do
    user = create(:user, anonymised_at: Time.zone.now)
    create(:message, status: "failed", created_at: 30.minutes.ago, user:, body: "hi")

    Sms::Client.expects(:new).never

    RetryFailedMessagesJob.new.perform
  end

  test "#perform does not retry failed messages belonging to non-contactable users" do
    user = create(:user, contactable: false)
    create(:message, status: "failed", created_at: 30.minutes.ago, user:, body: "hi")

    Sms::Client.expects(:new).never

    RetryFailedMessagesJob.new.perform
  end

  test "#perform reports errors to Appsignal and continues processing the remaining messages" do
    broken_message = create(:message, status: "failed", created_at: 30.minutes.ago)
    other_message = create(:message, status: "failed", created_at: 20.minutes.ago)

    Sms::Client.expects(:new).with(broken_message).raises(StandardError, "boom")
    client = mock
    client.expects(:send_message)
    Sms::Client.expects(:new).with(other_message).returns(client)
    Appsignal.expects(:report_error)

    RetryFailedMessagesJob.new.perform
  end
end
