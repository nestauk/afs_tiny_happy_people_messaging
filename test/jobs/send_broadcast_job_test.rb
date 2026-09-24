require "test_helper"

class SendBroadcastJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#perform sends messages to all matching users" do
    matching_users = create_list(:user, 3)
    non_matching_user = create(:user)
    broadcast = create(:broadcast, recipient_ids: matching_users.map(&:id))

    assert_enqueued_jobs matching_users.count do
      SendBroadcastJob.perform_now(broadcast)
    end

    matching_users.each do |user|
      assert_enqueued_with(job: SendCustomMessageJob)
    end

    assert_nil Message.find_by(user: non_matching_user, broadcast: broadcast)
    assert_not_nil broadcast.sent_at
  end

  test "#perform creates a SurveySend if the broadcast has a survey" do
    survey = create(:survey)
    user = create(:user)
    broadcast = create(:broadcast, recipient_ids: [user.id], survey: survey)

    SendBroadcastJob.perform_now(broadcast)

    assert_not_nil SurveySend.find_by(user: user, survey: survey)
  end

  test "#perform does not send a broadcast if the messsage fails to persist" do
    user = create(:user)
    broadcast = create(:broadcast, recipient_ids: [user.id])

    Appsignal.expects(:report_error)

    Message.stubs(:create!).raises(ActiveRecord::RecordInvalid.new(Message.new))
    SendBroadcastJob.perform_now(broadcast)

    assert_nil Message.find_by(user: user, broadcast: broadcast)
    assert_nil SurveySend.find_by(user: user, survey: broadcast.survey)
  end

  test "#perform does not mark the broadcast as sent if every message fails to persist" do
    user = create(:user)
    broadcast = create(:broadcast, recipient_ids: [user.id])

    Appsignal.expects(:report_error)

    Message.stubs(:create!).raises(ActiveRecord::RecordInvalid.new(Message.new))
    SendBroadcastJob.perform_now(broadcast)

    assert_nil broadcast.reload.sent_at
  end

  test "#perform rescues database errors when persisting a message" do
    user = create(:user)
    broadcast = create(:broadcast, recipient_ids: [user.id])

    Appsignal.expects(:report_error)

    Message.stubs(:create!).raises(ActiveRecord::StatementInvalid.new("connection lost"))
    SendBroadcastJob.perform_now(broadcast)

    assert_nil broadcast.reload.sent_at
  end

  test "#perform does not re-message users who already received this broadcast" do
    user = create(:user)
    broadcast = create(:broadcast, recipient_ids: [user.id])
    create(:message, user: user, broadcast: broadcast)

    assert_no_enqueued_jobs only: SendCustomMessageJob do
      SendBroadcastJob.perform_now(broadcast)
    end

    assert_equal 1, Message.where(user: user, broadcast: broadcast).count
  end

  test "#perform does not create a SurveySend if the message fails to persist" do
    survey = create(:survey)
    user = create(:user)
    broadcast = create(:broadcast, recipient_ids: [user.id], survey: survey)
    Appsignal.expects(:report_error)

    Message.stubs(:create!).raises(ActiveRecord::RecordInvalid.new(Message.new))
    SendBroadcastJob.perform_now(broadcast)

    assert_nil SurveySend.find_by(user: user, survey: survey)
  end

  test "#perform if message fails for one user, it still sends messages to other users" do
    failing_user = create(:user)
    succeeding_user = create(:user)
    broadcast = create(:broadcast, recipient_ids: [failing_user.id, succeeding_user.id])
    Appsignal.expects(:report_error)

    Message.stubs(:create!).with(has_entry(user: failing_user)).raises(ActiveRecord::RecordInvalid.new(Message.new))
    Message.stubs(:create!).with(has_entry(user: succeeding_user)).returns(create(:message, user: succeeding_user))

    assert_enqueued_jobs 1 do
      SendBroadcastJob.perform_now(broadcast)
    end

    assert_not_nil broadcast.sent_at
  end
end
