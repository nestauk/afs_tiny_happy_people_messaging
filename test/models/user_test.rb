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

  test "child_birthday is within the last 27 months on create" do
    assert_raises ActiveRecord::RecordInvalid do
      create(:user, child_birthday: Time.now - 28.months)
    end
  end

  test "child_birthday is not less than 3 months on create" do
    assert_raises ActiveRecord::RecordInvalid do
      create(:user, child_birthday: Time.now - 2.months)
    end
  end

  test "child_birthday is not validated on update" do
    @subject.update(child_birthday: Time.now + 28.months)

    assert @subject.valid?
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
    create(:user, hour_preference: "afternoon")
    create(:user, hour_preference: "evening")
    create(:user, hour_preference: "no_preference")
    morning_user = create(:user, hour_preference: "morning")

    assert_equal User.wants_morning_message.size, 1
    assert_equal User.wants_morning_message, [morning_user]
  end

  test "wants_afternoon_message scope" do
    create(:user, hour_preference: "morning")
    create(:user, hour_preference: "evening")
    create(:user, hour_preference: "no_preference")
    afternoon_user = create(:user, hour_preference: "afternoon")

    assert_equal User.wants_afternoon_message.size, 1
    assert_equal User.wants_afternoon_message, [afternoon_user]
  end

  test "wants_evening_message scope" do
    create(:user, hour_preference: "afternoon")
    create(:user, hour_preference: "morning")
    create(:user, hour_preference: "no_preference")
    evening_user = create(:user, hour_preference: "evening")

    assert_equal User.wants_evening_message.size, 1
    assert_equal User.wants_evening_message, [evening_user]
  end

  test "no_hour_preference_message scope" do
    create(:user, hour_preference: "afternoon")
    create(:user, hour_preference: "evening")
    create(:user, hour_preference: "morning")
    no_preference = create(:user, hour_preference: "no_preference")

    # This includes the subject user set up
    assert_equal User.no_hour_preference_message.size, 2
    assert_includes User.no_hour_preference_message, @subject
    assert_includes User.no_hour_preference_message, no_preference
  end

  test "with_preference_for_day scope" do
    create(:user, day_preference: 1)
    create(:user, day_preference: 2)
    create(:user, day_preference: 3)
    user = create(:user, day_preference: 4)

    assert_equal User.with_preference_for_day(4).size, 1
    assert_equal User.with_preference_for_day(4), [user]
  end

  test "not_clicked_last_x_messages scope" do
    content = create(:content)
    user1 = create(:user)
    create(:message, user: user1, body: "https://thp-text.uk/m", content:)
    create(:message, user: user1, body: "https://thp-text.uk/m", content:)
    create(:message, user: user1, body: "https://thp-text.uk/m", content:)

    user2 = create(:user)
    create(:message, user: user2, body: "https://thp-text.uk/m", content:)
    create(:message, user: user2, body: "https://thp-text.uk/m", clicked_at: Time.now, content:)
    create(:message, user: user2, body: "https://thp-text.uk/m", content:)
    create(:message, user: user2, body: "https://thp-text.uk/m", clicked_at: Time.now, content:)
    create(:message, user: user2, body: "https://thp-text.uk/m", content:)
    create(:message, user: user2, body: "https://thp-text.uk/m", clicked_at: Time.now, content:)

    user3 = create(:user)
    create(:message, user: user3, body: "https://thp-text.uk/m", content:)
    create(:message, user: user3, body: "https://thp-text.uk/m", content:)
    create(:message, user: user3, body: "https://thp-text.uk/m", content:, clicked_at: Time.now)
    create(:message, user: user3, body: "https://thp-text.uk/m", content:)

    user4 = create(:user)
    create(:message, user: user4, body: "https://thp-text.uk/m")
    create(:message, user: user4, body: "https://thp-text.uk/m")

    user5 = create(:user)
    create(:message, user: user5, body: "https://thp-text.uk/m", content:)
    create(:message, user: user5, body: "https://thp-text.uk/m", content:)
    create(:message, user: user5, body: "hi please fill this out", content:)

    assert_equal User.not_clicked_last_x_messages(3).to_a.size, 1
    assert_equal User.not_clicked_last_x_messages(3), [user1]
  end

  test "received_two_messages scope" do
    content = create(:content)

    user1 = create(:user)
    create(:message, user: user1, content:)
    create(:message, user: user1, content:)

    user2 = create(:user)
    create(:message, user: user2, content:)
    create(:message, user: user2)

    user3 = create(:user)
    create(:message, user: user3)
    create(:message, user: user3)

    assert_equal User.received_two_messages.to_a.size, 1
    assert_equal User.received_two_messages, [user1]
  end

  test "not_finished_content scope" do
    group = create(:group)
    content1 = create(:content, position: 1, group:)
    content2 = create(:content, position: 2, group:)
    content3 = create(:content, position: 3, group:)

    create(:user, last_content_id: content3.id)

    user2 = create(:user, last_content_id: content2.id)
    user3 = create(:user, last_content_id: content1.id)
    @subject.update(last_content_id: nil)

    assert_equal 3, User.not_finished_content.length
    assert_includes User.not_finished_content, user2
    assert_includes User.not_finished_content, user3
    assert_includes User.not_finished_content, @subject
  end

  test "full_name method" do
    user = create(:user, first_name: "John", last_name: "Doe")

    assert_equal user.full_name, "John Doe"
  end

  test "child_age_in_months_today method" do
    user = create(:user, child_birthday: Time.now - 7.months)

    assert_equal user.child_age_in_months_today, 7
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

  test "#next_content does not return archived content" do
    group = create(:group)
    content1 = create(:content, group:, position: 1)
    create(:content, group:, position: 2, archived_at: Time.now)
    content3 = create(:content, group:, position: 3)
    @subject.update(last_content_id: content1.id)

    assert_equal @subject.next_content, content3
  end

  test "#next_content returns correct next content if user is on archived content" do
    group = create(:group)
    content1 = create(:content, group:, position: 1, archived_at: Time.now)
    content2 = create(:content, group:, position: 2)
    create(:content, group:, position: 3)
    @subject.update(last_content_id: content1.id)

    assert_equal @subject.next_content, content2
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

  test "#update_local_authority method" do
    user = create(:user, postcode: "SW1A 1AA")

    geocode_payload = Geokit::GeoLoc.new(state: "Islington", country_code: "England")
    LocationGeocoder.any_instance.stubs(:geocode).returns(geocode_payload)

    user.update_local_authority

    assert_equal "Islington", user.local_authority.name
    assert_equal "England", user.local_authority.country
  end

  test "#update_local_authority method doesn't fail if geocoding fails" do
    user = create(:user, postcode: "SW1A 1AA")

    LocationGeocoder.any_instance.stubs(:geocode).raises(Geokit::Geocoders::GeocodeError)

    assert_nothing_raised { user.update_local_authority }
  end
end
