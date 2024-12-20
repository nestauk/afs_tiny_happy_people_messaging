# FILEPATH: /Users/celia.collins/Code/afs_tiny_happy_people/test/models/user_test.rb

require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup { @subject = create(:user) }

  test "should be valid" do
    assert @subject.valid?
  end

  test "has_many messages" do
    create(:message, user: @subject)
    assert_equal(1, @subject.messages.size)
  end

  test "has_many interests" do
    create(:interest, user: @subject)
    assert_equal(1, @subject.interests.size)
  end

  test("phone_number required") { assert_present(:phone_number) }
  test("first_name required") { assert_present(:first_name) }
  test("last_name required") { assert_present(:last_name) }
  test("child_birthday required") { assert_present(:child_birthday) }

  test "child_birthday is within the last 5 years" do
    @subject.child_birthday = Time.now - 6.years
    assert_not @subject.valid?

    @subject.child_birthday = Time.now + 1.month
    assert_not @subject.valid?
  end

  test "contactable scope" do
    create(:user, contactable: false)

    assert_equal User.contactable.size, 1
    assert_equal User.contactable, [@subject]
  end

  test "opted_out scope" do
    user = create(:user, contactable: false)

    assert_equal User.opted_out.size, 1
    assert_equal User.opted_out, [user]
  end

  test "wants_morning_message scope" do
    create(:user, timing: "afternoon")
    create(:user, timing: "evening")
    create(:user, timing: "no_preference")
    morning_user = create(:user, timing: "morning")

    assert_equal User.wants_morning_message.size, 1
    assert_equal User.wants_morning_message, [morning_user]
  end

  test "wants_afternoon_message scope" do
    create(:user, timing: "morning")
    create(:user, timing: "evening")
    create(:user, timing: "no_preference")
    afternoon_user = create(:user, timing: "afternoon")

    assert_equal User.wants_afternoon_message.size, 1
    assert_equal User.wants_afternoon_message, [afternoon_user]
  end

  test "wants_evening_message scope" do
    create(:user, timing: "afternoon")
    create(:user, timing: "morning")
    create(:user, timing: "no_preference")
    evening_user = create(:user, timing: "evening")

    assert_equal User.wants_evening_message.size, 1
    assert_equal User.wants_evening_message, [evening_user]
  end

  test "no_preference_message scope" do
    create(:user, timing: "afternoon")
    create(:user, timing: "evening")
    create(:user, timing: "morning")
    no_preference = create(:user, timing: "no_preference")

    # This includes the subject user set up
    assert_equal User.no_preference_message.size, 2
    assert_includes User.no_preference_message, @subject
    assert_includes User.no_preference_message, no_preference
  end

  test "not_clicked_last_two_messages scope" do
    content = create(:content)
    user1 = create(:user)
    create(:message, user: user1, content:)
    create(:message, user: user1, content:)

    user2 = create(:user)
    create(:message, user: user2, content:)
    create(:message, user: user2, content:)
    create(:message, user: user2, clicked_at: Time.now, content:)
    create(:message, user: user2, clicked_at: Time.now, content:)

    user3 = create(:user)
    create(:message, user: user3, content:)
    create(:message, user: user3, content:, clicked_at: Time.now)
    create(:message, user: user3, content:)

    user4 = create(:user)
    create(:message, user: user4)
    create(:message, user: user4)

    assert_equal User.not_clicked_last_two_messages.to_a.size, 1
    assert_equal User.not_clicked_last_two_messages, [user1]
  end

  test "child_age_in_months_today method" do
    user = create(:user, child_birthday: Time.now - 5.months)

    assert_equal user.child_age_in_months_today, 5
  end

  test "adjusted_child_age_in_months_today method" do
    user = create(:user, child_birthday: Time.now - 5.months, adjust_amount: -1)

    assert_equal user.adjusted_child_age_in_months_today, 4
  end

  test "#next_content method returns next ranked content for age group" do
    group = create(:group)
    content1 = create(:content, group:, position: 1)
    content2 = create(:content, group:, position: 2)
    create(:content, group:, position: 3)
    @subject.update(last_content_id: content1.id)

    assert_equal @subject.next_content, content2
  end

  test "#next_content method returns nothing if no appropriate content" do
    group = create(:group)
    create(:content, group:, position: 1)
    content2 = create(:content, group:, position: 2)
    @subject.update(last_content_id: content2.id)

    assert_nil @subject.next_content
  end

  test "#next_content finds appropriate content if user has not had content before" do
    group = create(:group)
    content = create(:content, group:, position: 1, age_in_months: 18)
    create(:content, group:, position: 2, age_in_months: 18)
    create(:content, group:, position: 3, age_in_months: 19)

    assert_equal @subject.next_content, content
  end

  test "#next_content does not return content that the user has already seen" do
    # This is in case the content order has been switched around by the admins
    group = create(:group)
    content1 = create(:content, group:, position: 1)
    content2 = create(:content, group:, position: 2)
    content3 = create(:content, group:, position: 3)
    create(:message, user: @subject, content: content2)
    @subject.update(last_content_id: content1.id)

    assert_equal @subject.next_content, content3
  end

  test "#had_content_this_week? method returns true if user has had content" do
    user = create(:user)
    content = create(:content)
    create(:message, user: user, content: content, created_at: Time.now - 1.day)

    assert_equal true, user.had_content_this_week?
  end

  test "#had_content_this_week? method returns false if user has not had content" do
    user = create(:user)

    assert_equal false, user.had_content_this_week?
  end

  test "#adjust_age method decreases adjust_amount by 1" do
    user = create(:user, adjust_amount: -2)
    user.adjust_age

    assert_equal user.adjust_amount, -3
  end
end
