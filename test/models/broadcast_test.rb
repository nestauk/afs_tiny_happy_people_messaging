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

  test "requires recipient_ids" do
    @broadcast.recipient_ids = []
    assert_not @broadcast.valid?
  end

  test "parses recipient_ids pasted as a comma and newline separated string" do
    @broadcast.recipient_ids = "12, 45\n190"
    assert_equal [12, 45, 190], @broadcast.recipient_ids
  end

  test "deduplicates pasted recipient_ids" do
    @broadcast.recipient_ids = "12, 12, 45"
    assert_equal [12, 45], @broadcast.recipient_ids
  end

  test "validates recipient_ids only contain valid user id values" do
    @broadcast.recipient_ids = "12, abc, 45"
    assert_not @broadcast.valid?
    assert_includes @broadcast.errors[:recipient_ids].join, "abc"
  end

  test "validates recipient_ids correspond to real users" do
    user = create(:user)
    @broadcast.recipient_ids = [user.id, user.id + 100_000]

    assert_not @broadcast.valid?
    assert_includes @broadcast.errors[:recipient_ids].join, (user.id + 100_000).to_s
  end

  test "validates survey is present if {{survey_link}} placeholder is used" do
    @broadcast.body_en = "Please complete the survey: {{survey_link}}"
    @broadcast.survey = nil
    assert_not @broadcast.valid?
  end

  test "matching_users returns users with the specified recipient_ids" do
    user1 = create(:user)
    user2 = create(:user)
    other_user = create(:user)

    @broadcast.recipient_ids = [user1.id, user2.id]

    assert_includes @broadcast.matching_users, user1
    assert_includes @broadcast.matching_users, user2
    assert_not_includes @broadcast.matching_users, other_user
  end

  test "matching_users excludes opted-out users" do
    opted_out_user = create(:user, contactable: false)
    contactable_user = create(:user)

    @broadcast.recipient_ids = [opted_out_user.id, contactable_user.id]

    assert_not_includes @broadcast.matching_users, opted_out_user
    assert_includes @broadcast.matching_users, contactable_user
  end

  test "matching_users excludes anonymised users" do
    anonymised_user = create(:user, anonymised_at: Time.zone.now)
    non_anonymised_user = create(:user)

    @broadcast.recipient_ids = [anonymised_user.id, non_anonymised_user.id]

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
