require "test_helper"

class BroadcastTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @broadcast = build(:broadcast)
  end

  test "should be valid" do
    assert @broadcast.valid?
  end

  test "requires body_en" do
    @broadcast.body_en = nil
    assert_not @broadcast.valid?
  end

  test "requires body_cy" do
    @broadcast.body_cy = nil
    assert_not @broadcast.valid?
  end

  test "requires user_groups" do
    @broadcast.user_groups = []
    assert_not @broadcast.valid?
  end

  test "validates user_groups are recognised" do
    @broadcast.user_groups = ["unrecognised_group"]
    assert_not @broadcast.valid?
  end

  test "requires message_threshold if user_groups includes received_at_least_x_messages" do
    @broadcast.user_groups = ["received_at_least_x_messages"]
    @broadcast.message_threshold = nil
    assert_not @broadcast.valid?
  end

  test "validates survey is present if {{survey_link}} placeholder is used" do
    @broadcast.body_en = "Please complete the survey: {{survey_link}}"
    @broadcast.survey = nil
    assert_not @broadcast.valid?
  end

  test "matching_users returns users in the specified groups" do
    user1 = create(:user)
    user1.update(created_at: Date.new(2025, 0o6, 1))
    user2 = create(:user)
    user3 = create(:user)

    @broadcast.user_groups = ["welsh_pilot"]
    assert_includes @broadcast.matching_users, user2
    assert_includes @broadcast.matching_users, user3
    assert_not_includes @broadcast.matching_users, user1
  end

  test "matching_users returns the intersection of users when multiple groups are selected" do
    group = create(:group, language: "esp")
    content = create(:content, group:)

    in_pilot_with_message = create(:user, created_at: Date.new(2026, 0o5, 2))
    create(:message, user: in_pilot_with_message, content:)

    in_pilot_without_message = create(:user, created_at: Date.new(2026, 0o5, 2))

    not_in_pilot_with_message = create(:user, created_at: Date.new(2026, 0o4, 30))
    create(:message, user: not_in_pilot_with_message, content:)

    @broadcast.user_groups = ["welsh_pilot", "received_at_least_x_messages"]
    @broadcast.message_threshold = 1

    assert_includes @broadcast.matching_users, in_pilot_with_message
    assert_not_includes @broadcast.matching_users, in_pilot_without_message
    assert_not_includes @broadcast.matching_users, not_in_pilot_with_message
  end

  test "matching_users excludes opted-out users" do
    opted_out_user = create(:user, created_at: Date.new(2026, 0o5, 2), contactable: false)
    contactable_user = create(:user, created_at: Date.new(2026, 0o5, 2))

    @broadcast.user_groups = ["welsh_pilot"]

    assert_not_includes @broadcast.matching_users, opted_out_user
    assert_includes @broadcast.matching_users, contactable_user
  end

  test "matching_users excludes anonymised users" do
    anonymised_user = create(:user, created_at: Date.new(2026, 0o5, 2), anonymised_at: Time.zone.now)
    non_anonymised_user = create(:user, created_at: Date.new(2026, 0o5, 2))

    @broadcast.user_groups = ["welsh_pilot"]

    assert_not_includes @broadcast.matching_users, anonymised_user
    assert_includes @broadcast.matching_users, non_anonymised_user
  end

  test "save_and_send! saves the broadcast and enqueues a job" do
    assert_difference "Broadcast.count", 1 do
      assert_enqueued_with(job: SendBroadcastJob) do
        @broadcast.save_and_send!
      end
    end
  end

  test "save_and_send! rolls back if save fails" do
    @broadcast.body_en = nil

    assert_no_difference "Broadcast.count" do
      assert_no_enqueued_jobs do
        assert_raises(ActiveRecord::RecordInvalid) do
          @broadcast.save_and_send!
        end
      end
    end
  end
end
