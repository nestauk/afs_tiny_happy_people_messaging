require "test_helper"

class SendBroadcastJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#perform sends messages to all matching users" do
    broadcast = create(:broadcast, user_groups: ["welsh_pilot"])
    matching_users = create_list(:user, 3, created_at: Date.new(2026, 05, 2))
    non_matching_user = create(:user, created_at: Date.new(2026, 04, 30))

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
    broadcast = create(:broadcast, user_groups: ["welsh_pilot"], survey: survey)
    user = create(:user)

    SendBroadcastJob.perform_now(broadcast)

    assert_not_nil SurveySend.find_by(user: user, survey: survey)
  end

  test "#perform does not send a broadcast if the messsage fails to persist" do
    broadcast = create(:broadcast, user_groups: ["welsh_pilot"])
    user = create(:user)

    Appsignal.expects(:report_error)

    Message.stubs(:create!).raises(ActiveRecord::RecordInvalid.new(Message.new))
    SendBroadcastJob.perform_now(broadcast)
 
    assert_nil Message.find_by(user: user, broadcast: broadcast)
    assert_nil SurveySend.find_by(user: user, survey: broadcast.survey)
  end

  test "#perform does not create a SurveySend if the message fails to persist" do
    survey = create(:survey)
    broadcast = create(:broadcast, user_groups: ["welsh_pilot"], survey: survey)
    user = create(:user)
    Appsignal.expects(:report_error)

    Message.stubs(:create!).raises(ActiveRecord::RecordInvalid.new(Message.new))
    SendBroadcastJob.perform_now(broadcast)

    assert_nil SurveySend.find_by(user: user, survey: survey)
  end

  test "#perform if message fails for one user, it still sends messages to other users" do
    broadcast = create(:broadcast, user_groups: ["welsh_pilot"])
    failing_user = create(:user)
    succeeding_user = create(:user)
    Appsignal.expects(:report_error)

    Message.stubs(:create!).with(has_entry(user: failing_user)).raises(ActiveRecord::RecordInvalid.new(Message.new))
    Message.stubs(:create!).with(has_entry(user: succeeding_user)).returns(create(:message, user: succeeding_user))

    assert_enqueued_jobs 1 do
      SendBroadcastJob.perform_now(broadcast)
    end

    assert_not_nil broadcast.sent_at
  end
end
